import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:activity_tracker/models/body_stats_model.dart';
import 'package:activity_tracker/services/coach_service.dart';
import 'package:activity_tracker/services/local_coach_service.dart';
import 'package:activity_tracker/services/plan_export_service.dart';

void main() {
  test('All programme weeks contain seven days and stay in their phase', () {
    final stats = BodyStats.defaults();
    for (var week = 1; week <= 52; week++) {
      final plan = CoachService.getWeeklyPlan(week, stats);
      expect(plan.days, hasLength(7));
      expect(plan.weekNumber, week);
      expect(plan.days.any((d) => d.type == 'rest'), isTrue);
    }
  });
  test('Medical questions take precedence over workout requests', () {
    expect(
      LocalCoachService.reply(
        'workout plan for knee pain',
        BodyStats.defaults(),
      ),
      contains('cannot diagnose'),
    );
    expect(
      LocalCoachService.reply('chest pain after workout', null),
      contains('emergency'),
    );
  });
  test('Missing profile does not produce invented personalized targets', () {
    expect(
      LocalCoachService.reply('my calories', null),
      contains('Set up your body profile'),
    );
  });
  test('Saved profile drives nutrition guidance', () {
    final stats = BodyStats.defaults();
    expect(
      LocalCoachService.reply('my calories', stats),
      contains('${stats.targetCalories.round()} kcal'),
    );
  });
  test('All plan types generate real PDF bytes without a server', () async {
    for (final type in ['workout', 'nutrition', 'full']) {
      final data = await PlanExportService.createPdf(
        type,
        BodyStats.defaults(),
      );
      expect(ascii.decode(data.take(5).toList()), '%PDF-');
      expect(data.length, greaterThan(1000));
    }
  });
}
