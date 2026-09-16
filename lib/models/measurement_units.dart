/// Storage remains kg, cm, g and kcal. These preferences affect input/display only.
class MeasurementUnits {
  final bool pounds, feetInches, ounces, kilojoules;
  const MeasurementUnits({
    this.pounds = false,
    this.feetInches = false,
    this.ounces = false,
    this.kilojoules = false,
  });
  static const metric = MeasurementUnits();
  static const imperial = MeasurementUnits(
    pounds: true,
    feetInches: true,
    ounces: true,
  );
  static const kgPerPound = 0.45359237;
  static const gramsPerOunce = 28.349523125;
  String get weightUnit => pounds ? 'lb' : 'kg';
  String get foodUnit => ounces ? 'oz' : 'g';
  String get energyUnit => kilojoules ? 'kJ' : 'kcal';
  double weightValue(double kg) => pounds ? kg / kgPerPound : kg;
  double weightKg(double value) => pounds ? value * kgPerPound : value;
  double foodValue(double grams) => ounces ? grams / gramsPerOunce : grams;
  double foodGrams(double value) => ounces ? value * gramsPerOunce : value;
  double energyValue(double kcal) => kilojoules ? kcal * 4.184 : kcal;
  double energyKcal(double value) => kilojoules ? value / 4.184 : value;
  String weight(double kg, {int decimals = 1}) =>
      '${weightValue(kg).toStringAsFixed(decimals)} $weightUnit';
  String food(double grams) =>
      '${foodValue(grams).toStringAsFixed(ounces ? 2 : 0)} $foodUnit';
  String energy(double kcal) => '${energyValue(kcal).round()} $energyUnit';
  static (int, double) heightParts(double cm) {
    final inches = (cm / 2.54 * 100).round() / 100;
    final feet = (inches / 12).floor();
    return (feet, inches - feet * 12);
  }

  static double? parseHeight(String main, String inches, bool imperial) {
    final value = double.tryParse(main.trim());
    if (value == null || !value.isFinite) return null;
    if (!imperial) return value;
    final inch = double.tryParse(inches.trim());
    if (value != value.floorToDouble() ||
        value < 0 ||
        inch == null ||
        !inch.isFinite ||
        inch < 0 ||
        inch >= 12) {
      return null;
    }
    return (value * 12 + inch) * 2.54;
  }

  String height(double cm) {
    if (!feetInches) return '${cm.toStringAsFixed(1)} cm';
    // Round total inches before splitting so 11.96 inches carries to next foot.
    final tenths = (cm / 2.54 * 10).round();
    return '${tenths ~/ 120} ft ${(tenths % 120 / 10).toStringAsFixed(1)} in';
  }

  MeasurementUnits copyWith({
    bool? pounds,
    bool? feetInches,
    bool? ounces,
    bool? kilojoules,
  }) => MeasurementUnits(
    pounds: pounds ?? this.pounds,
    feetInches: feetInches ?? this.feetInches,
    ounces: ounces ?? this.ounces,
    kilojoules: kilojoules ?? this.kilojoules,
  );
  Map<String, dynamic> toMap() => {
    'pounds': pounds,
    'feetInches': feetInches,
    'ounces': ounces,
    'kilojoules': kilojoules,
  };
  factory MeasurementUnits.fromMap(Map<String, dynamic> map) =>
      MeasurementUnits(
        pounds: map['pounds'] == true,
        feetInches: map['feetInches'] == true,
        ounces: map['ounces'] == true,
        kilojoules: map['kilojoules'] == true,
      );
}
