import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:activity_tracker/models/body_stats_model.dart';
import 'package:activity_tracker/models/coaching_preferences.dart';
import 'package:activity_tracker/services/adaptive_plan_service.dart';
import 'package:activity_tracker/services/coaching_knowledge.dart';
import 'package:activity_tracker/services/local_coach_service.dart';
import 'package:activity_tracker/services/plan_export_service.dart';
import 'package:activity_tracker/services/word_plan_export.dart';
import 'package:activity_tracker/widgets/coaching_plan_view.dart';
import 'package:activity_tracker/screens/coaching_assessment_screen.dart';

void main() {
  final now = DateTime(2026, 9, 11, 12);
  final stats = BodyStats.defaults().copyWith(goal: 'muscle_gain');
  test(
    'Fresh recovery and logged strength days control progression; stale data holds',
    () {
      final ready = AdaptivePlanService.generate(
        stats,
        now: now,
        preferences: CoachingPreferences(checkedAt: now, recovery: 'Recovered'),
        recentStrengthDays: 3,
      );
      expect(ready.workouts.join(), contains('3 sets'));
      final stale = AdaptivePlanService.generate(
        stats,
        now: now,
        preferences: CoachingPreferences(
          checkedAt: now.subtract(const Duration(days: 8)),
          recovery: 'Recovered',
        ),
        recentStrengthDays: 3,
      );
      expect(stale.workouts.join(), contains('2 sets'));
      final tired = AdaptivePlanService.generate(
        stats,
        now: now,
        preferences: CoachingPreferences(checkedAt: now, recovery: 'Tired'),
        recentStrengthDays: 3,
      );
      expect(tired.phase, 'Recovery week');
      expect(tired.workouts.join(), contains('1 sets'));
      expect(
        AdaptivePlanService.generate(
          stats,
          now: now,
          preferences: CoachingPreferences(
            checkedAt: now,
            recovery: 'Recovered',
          ),
          recentStrengthDays: 1,
        ).workouts.join(),
        contains('2 sets'),
      );
    },
  );
  test(
    'Equipment and experience shape training; symptoms pause prescriptions',
    () {
      final home = AdaptivePlanService.generate(
        stats,
        preferences: const CoachingPreferences(
          equipment: 'Bodyweight',
          sessions: 4,
        ),
      );
      expect(home.workouts.where((d) => d.contains('Full-body')).length, 3);
      expect(home.workouts.join().toLowerCase(), isNot(contains('dumbbell')));
      final gym = AdaptivePlanService.generate(
        stats,
        preferences: const CoachingPreferences(
          equipment: 'Gym',
          experience: 'Experienced',
          sessions: 4,
        ),
      );
      expect(gym.workouts.join(), contains('Seated cable row'));
      expect(gym.workouts.where((d) => d.contains('Upper-body')).length, 2);
      for (final preferences in [
        const CoachingPreferences(pain: true),
        const CoachingPreferences(medical: true),
      ]) {
        final plan = AdaptivePlanService.generate(
          stats,
          preferences: preferences,
        );
        expect(plan.meals, isEmpty);
        expect(plan.workouts, isEmpty);
        expect(plan.lines('full').join(), contains('prescriptions are paused'));
        expect(
          LocalCoachService.reply('my workout', stats, plan: plan),
          contains('paused'),
        );
      }
    },
  );
  test(
    'Meal portions honor exclusions and energy estimates remain consistent',
    () {
      for (final diet in ['Vegetarian', 'Vegan', 'Mixed diet']) {
        for (final excluded in [
          <String>[],
          ['Milk', 'Soy', 'Gluten', 'Fish', 'Seeds'],
        ]) {
          final plan = AdaptivePlanService.generate(
            stats,
            diet: diet,
            preferences: CoachingPreferences(exclusions: excluded),
          );
          expect(plan.mealDays, hasLength(7));
          for (final day in plan.mealDays) {
            expect(
              day.calories,
              closeTo(
                plan.stats.targetCalories,
                plan.stats.targetCalories * .025,
              ),
            );
            for (final meal in day.meals) {
              expect(
                meal.calories,
                closeTo(meal.protein * 4 + meal.carbs * 4 + meal.fat * 9, .001),
              );
              for (final portion in meal.portions) {
                expect(portion.grams, greaterThan(0));
                expect(
                  portion.food.allergens.where(excluded.contains),
                  isEmpty,
                );
              }
            }
          }
          expect(plan.shopping, isNotEmpty);
        }
      }
    },
  );
  test(
    'Trend requires separate days, excludes future readings and reports weekly averages',
    () {
      final sparse = stats.copyWith(
        weightHistory: List.generate(
          5,
          (i) =>
              WeightEntry(date: now.subtract(Duration(hours: i)), weightKg: 70),
        ),
      );
      expect(
        AdaptivePlanService.weightInsight(sparse, now),
        contains('at least three'),
      );
      final data = [
        for (final d in [1, 2, 3])
          WeightEntry(date: now.subtract(Duration(days: d)), weightKg: 76),
        for (final d in [8, 9, 10])
          WeightEntry(date: now.subtract(Duration(days: d)), weightKg: 75),
        WeightEntry(date: now.add(const Duration(days: 1)), weightKg: 200),
      ];
      expect(
        AdaptivePlanService.weightInsight(
          stats.copyWith(weightHistory: data),
          now,
        ),
        contains('+1.00 kg'),
      );
      expect(
        AdaptivePlanService.generate(
          stats.copyWith(weightHistory: data),
          now: now,
        ).stats.targetCalories,
        stats.targetCalories,
      );
    },
  );
  test(
    'Textbook summaries cite known references and share export content',
    () async {
      expect(CoachingKnowledge.references, hasLength(6));
      expect(
        CoachingKnowledge.answer('help with motivation'),
        contains('Transformation Specialist'),
      );
      expect(
        CoachingKnowledge.answer('how do I manage recovery'),
        contains('Bodybuilding'),
      );
      final plan = AdaptivePlanService.generate(stats, now: now);
      final pdf = await PlanExportService.createAdaptivePdf(plan, 'full');
      expect(ascii.decode(pdf.take(5).toList()), '%PDF-');
      final dir = Directory('/tmp/activity-coaching-preview');
      await dir.create(recursive: true);
      await File(
        '${dir.path}/example-plan.docx',
      ).writeAsBytes(WordPlanExport.create(plan, 'full'));
      await File('${dir.path}/example-plan.pdf').writeAsBytes(pdf);
    },
  );
  for (final width in [360.0, 1280.0]) {
    testWidgets('Coaching plan and assessment fit width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CoachingPlanView(
                plan: AdaptivePlanService.generate(stats),
              ),
            ),
          ),
        ),
      );
      for (final section in ['Nutrition', 'Training', 'Sources', 'Overview']) {
        await tester.tap(find.text(section).first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(
        const MaterialApp(
          home: CoachingAssessmentScreen(initial: CoachingPreferences()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
