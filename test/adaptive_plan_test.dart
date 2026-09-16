import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:activity_tracker/models/body_stats_model.dart';
import 'package:activity_tracker/models/goal_model.dart';
import 'package:activity_tracker/services/adaptive_plan_service.dart';
import 'package:activity_tracker/services/word_plan_export.dart';

void main() {
  GoalModel goal(String category, double value) => GoalModel(
    id: '1',
    title: 'Training & consistency',
    category: category,
    targetValue: 10,
    currentValue: value,
  );
  test('Only completed linked fitness goal transitions to maintenance', () {
    final stats = BodyStats.defaults().copyWith(
      goal: 'fat_loss',
      activityLevel: 'moderate',
    );
    final before = AdaptivePlanService.generate(
      stats,
      goal: goal('fitness', 9),
    );
    final after = AdaptivePlanService.generate(
      stats,
      goal: goal('fitness', 10),
    );
    expect(before.stats.goal, 'fat_loss');
    expect(after.stats.goal, 'maintain');
    expect(after.workouts.where((s) => s.contains('Full-body')).length, 2);
    expect(before.workouts.where((s) => s.contains('Full-body')).length, 3);
    expect(
      AdaptivePlanService.generate(stats, goal: goal('finance', 10)).stats.goal,
      'fat_loss',
    );
    expect(AdaptivePlanService.generate(stats).stats.goal, 'fat_loss');
  });
  test(
    'Weight changes update targets and vegan meals exclude animal foods',
    () {
      final stats = BodyStats.defaults();
      final a = AdaptivePlanService.generate(stats, diet: 'Vegan');
      final b = AdaptivePlanService.generate(
        stats.copyWith(weightKg: stats.weightKg + 5),
      );
      expect(a.stats.targetCalories, isNot(b.stats.targetCalories));
      expect(a.meals, hasLength(7));
      expect(a.workouts, hasLength(7));
      expect(
        a.meals.join(' '),
        isNot(matches(RegExp(r'chicken|fish|eggs|yogurt'))),
      );
      expect(
        () => AdaptivePlanService.generate(stats.copyWith(age: 12)),
        throwsArgumentError,
      );
    },
  );
  test(
    'Word exports contain real document package and selected plan sections',
    () {
      final plan = AdaptivePlanService.generate(
        BodyStats.defaults(),
        goal: goal('fitness', 10),
      );
      for (final type in ['full', 'nutrition', 'workout']) {
        final archive = ZipDecoder().decodeBytes(
          WordPlanExport.create(plan, type),
        );
        expect(archive.findFile('[Content_Types].xml'), isNotNull);
        expect(archive.findFile('_rels/.rels'), isNotNull);
        final xml = utf8.decode(archive.findFile('word/document.xml')!.content);
        expect(xml, contains('Training &amp; consistency'));
        expect(xml.contains('Weekly meal plan'), type != 'workout');
        expect(xml.contains('Weekly workout plan'), type != 'nutrition');
        expect(xml, contains('maintenance'));
      }
    },
  );
}
