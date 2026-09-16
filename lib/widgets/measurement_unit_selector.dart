import 'package:flutter/material.dart';
import '../models/measurement_units.dart';

class MeasurementUnitSelector extends StatelessWidget {
  final MeasurementUnits units;
  final ValueChanged<MeasurementUnits>? onChanged;
  const MeasurementUnitSelector({
    super.key,
    required this.units,
    required this.onChanged,
  });
  Widget choice(
    String label,
    bool value,
    String metric,
    String imperial,
    MeasurementUnits Function(bool) update,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: DropdownButtonFormField<bool>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem(value: false, child: Text(metric)),
        DropdownMenuItem(value: true, child: Text(imperial)),
      ],
      onChanged: onChanged == null
          ? null
          : (v) {
              if (v != null) onChanged!(update(v));
            },
    ),
  );
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Measurement units',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      Wrap(
        spacing: 8,
        children: [
          TextButton(
            onPressed: onChanged == null
                ? null
                : () => onChanged!(MeasurementUnits.metric),
            child: const Text('Use metric'),
          ),
          TextButton(
            onPressed: onChanged == null
                ? null
                : () => onChanged!(MeasurementUnits.imperial),
            child: const Text('Use imperial'),
          ),
        ],
      ),
      choice(
        'Body weight',
        units.pounds,
        'Kilograms (kg)',
        'Pounds (lb)',
        (v) => units.copyWith(pounds: v),
      ),
      choice(
        'Height',
        units.feetInches,
        'Centimeters (cm)',
        'Feet and inches (ft / in)',
        (v) => units.copyWith(feetInches: v),
      ),
      choice(
        'Food portions and nutrients',
        units.ounces,
        'Grams (g)',
        'Ounces (oz)',
        (v) => units.copyWith(ounces: v),
      ),
      choice(
        'Energy',
        units.kilojoules,
        'Calories (kcal)',
        'Kilojoules (kJ)',
        (v) => units.copyWith(kilojoules: v),
      ),
      const Text(
        'Save your profile to apply these choices throughout the app and downloads. Time and body-fat percentages use the same units in both systems.',
      ),
    ],
  );
}
