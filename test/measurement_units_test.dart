import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:activity_tracker/models/measurement_units.dart';
import 'package:activity_tracker/models/body_stats_model.dart';
import 'package:activity_tracker/services/adaptive_plan_service.dart';
import 'package:activity_tracker/services/word_plan_export.dart';
import 'package:activity_tracker/widgets/measurement_unit_selector.dart';
import 'package:activity_tracker/widgets/coaching_plan_view.dart';

void main() {
  const units = MeasurementUnits(
    pounds: true,
    feetInches: true,
    ounces: true,
    kilojoules: true,
  );
  test(
    'Known conversions and inverse conversions preserve physical measurements',
    () {
      expect(units.weightKg(100), closeTo(45.359237, 1e-9));
      expect(units.foodGrams(1), closeTo(28.349523125, 1e-9));
      expect(units.energyValue(100), closeTo(418.4, 1e-9));
      for (final value in [25.0, 75.123456, 400.0]) {
        expect(units.weightKg(units.weightValue(value)), closeTo(value, 1e-10));
        expect(units.foodGrams(units.foodValue(value)), closeTo(value, 1e-10));
        expect(
          units.energyKcal(units.energyValue(value)),
          closeTo(value, 1e-10),
        );
      }
      expect(
        MeasurementUnits.parseHeight('5', '9', true),
        closeTo(175.26, 1e-9),
      );
      expect(MeasurementUnits.parseHeight('5', '12', true), isNull);
      expect(MeasurementUnits.parseHeight('5.5', '0', true), isNull);
      expect(MeasurementUnits.parseHeight('5', '-1', true), isNull);
      expect(MeasurementUnits.parseHeight('NaN', '0', false), isNull);
      expect(units.height(182.88), '6 ft 0.0 in');
      expect(units.height(182.80), '6 ft 0.0 in');
    },
  );
  test(
    'Old profiles default to metric and unit changes preserve canonical data',
    () {
      final stats = BodyStats.defaults().copyWith(
        weightKg: 75.123456,
        heightCm: 175.26,
        weightHistory: [
          WeightEntry(date: DateTime(2026, 9, 1), weightKg: 76.123456),
        ],
      );
      final legacy = stats.toJson()..remove('units');
      expect(BodyStats.fromJson(legacy).units.pounds, isFalse);
      final changed = BodyStats.fromJson(stats.copyWith(units: units).toJson());
      expect(changed.units.kilojoules, isTrue);
      expect(changed.weightKg, stats.weightKg);
      expect(changed.heightCm, stats.heightCm);
      expect(
        changed.weightHistory.first.weightKg,
        stats.weightHistory.first.weightKg,
      );
      expect(changed.bmi, stats.bmi);
      expect(changed.targetCalories, stats.targetCalories);
    },
  );
  test(
    'Plans and Word exports convert quantities without changing the plan',
    () {
      final stats = BodyStats.defaults();
      final metric = AdaptivePlanService.generate(stats);
      final imperial = AdaptivePlanService.generate(
        stats.copyWith(units: units),
      );
      final text = imperial.lines('full').join('\n');
      expect(text, contains('165.3 lb'));
      expect(text, contains('ft'));
      expect(text, contains('oz'));
      expect(text, contains('kJ'));
      expect(imperial.mealDays.first.calories, metric.mealDays.first.calories);
      expect(imperial.workouts, metric.workouts);
      expect(imperial.shopping.join(), contains('oz for the week'));
      final zip = ZipDecoder().decodeBytes(
        WordPlanExport.create(imperial, 'full'),
      );
      expect(
        utf8.decode(zip.findFile('word/document.xml')!.content),
        contains('165.3 lb'),
      );
    },
  );
  for (final width in [360.0, 1280.0]) {
    testWidgets('Unit selector and imperial nutrition fit width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      MeasurementUnits selected = MeasurementUnits.metric;
      final selector = StatefulBuilder(
        builder: (context, setState) {
          return MeasurementUnitSelector(
            units: selected,
            onChanged: (u) => setState(() => selected = u),
          );
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: selector)),
        ),
      );
      await tester.tap(find.text('Use imperial'));
      await tester.pumpAndSettle();
      expect(selected.pounds, isTrue);
      expect(find.text('Pounds (lb)'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CoachingPlanView(
                plan: AdaptivePlanService.generate(
                  BodyStats.defaults().copyWith(units: units),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Nutrition'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
