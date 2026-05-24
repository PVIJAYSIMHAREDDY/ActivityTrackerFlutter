import '../services/firestore_service.dart';

class WeightEntry {
  final DateTime date;
  final double weightKg;

  const WeightEntry({
    required this.date,
    required this.weightKg,
  });

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      date: DateTime.parse(json['date'] as String),
      weightKg: (json['weightKg'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'weightKg': weightKg,
      };
}

class BodyStats {
  final double heightCm;
  final double weightKg;
  final int age;
  final String gender; // 'male' or 'female'
  final String activityLevel; // 'sedentary','light','moderate','active','athlete'
  final String goal; // 'fat_loss','maintain','muscle_gain','recomp'
  final double bodyFatPercent; // 0 if unknown
  final String phoneNumber;
  final DateTime programStartDate;
  final List<WeightEntry> weightHistory; // last 52 weeks

  const BodyStats({
    required this.heightCm,
    required this.weightKg,
    required this.age,
    required this.gender,
    required this.activityLevel,
    required this.goal,
    required this.bodyFatPercent,
    required this.phoneNumber,
    required this.programStartDate,
    required this.weightHistory,
  });

  // ---------------------------------------------------------------------------
  // Computed properties
  // ---------------------------------------------------------------------------

  double get bmi {
    final heightM = heightCm / 100.0;
    return weightKg / (heightM * heightM);
  }

  bool get needsWeightUpdate {
    if (weightHistory.isEmpty) return true;
    final sorted = List<WeightEntry>.from(weightHistory)
      ..sort((a, b) => b.date.compareTo(a.date));
    final lastEntry = sorted.first;
    return DateTime.now().difference(lastEntry.date).inDays > 7;
  }

  /// Mifflin-St Jeor BMR
  double get bmr {
    if (gender.toLowerCase() == 'female') {
      // Women: 10*weight(kg) + 6.25*height(cm) - 5*age - 161
      return 10.0 * weightKg + 6.25 * heightCm - 5.0 * age - 161.0;
    } else {
      // Men: 10*weight(kg) + 6.25*height(cm) - 5*age + 5
      return 10.0 * weightKg + 6.25 * heightCm - 5.0 * age + 5.0;
    }
  }

  static const Map<String, double> _activityMultipliers = {
    'sedentary': 1.2,
    'light': 1.375,
    'moderate': 1.55,
    'active': 1.725,
    'athlete': 1.9,
  };

  /// Total Daily Energy Expenditure = BMR * activity multiplier
  double get tdee {
    final multiplier = _activityMultipliers[activityLevel.toLowerCase()] ?? 1.375;
    return bmr * multiplier;
  }

  /// Target calories adjusted for goal
  double get targetCalories {
    switch (goal.toLowerCase()) {
      case 'fat_loss':
        return tdee * 0.80;
      case 'muscle_gain':
        return tdee * 1.10;
      case 'recomp':
        return tdee * 0.95;
      case 'maintain':
      default:
        return tdee;
    }
  }

  /// Protein in grams per day
  double get targetProtein {
    switch (goal.toLowerCase()) {
      case 'fat_loss':
        return weightKg * 2.2;
      case 'muscle_gain':
        return weightKg * 1.8;
      default:
        return weightKg * 2.0;
    }
  }

  /// Fat in grams per day (25% of target calories / 9 kcal per gram)
  double get targetFat {
    return (targetCalories * 0.25) / 9.0;
  }

  /// Carbs in grams per day — remaining calories after protein and fat are allocated
  double get targetCarbs {
    final proteinCalories = targetProtein * 4.0;
    final fatCalories = targetFat * 9.0;
    final remaining = targetCalories - proteinCalories - fatCalories;
    return remaining > 0 ? remaining / 4.0 : 0.0;
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  BodyStats copyWith({
    double? heightCm,
    double? weightKg,
    int? age,
    String? gender,
    String? activityLevel,
    String? goal,
    double? bodyFatPercent,
    String? phoneNumber,
    DateTime? programStartDate,
    List<WeightEntry>? weightHistory,
  }) {
    return BodyStats(
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      bodyFatPercent: bodyFatPercent ?? this.bodyFatPercent,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      programStartDate: programStartDate ?? this.programStartDate,
      weightHistory: weightHistory ?? this.weightHistory,
    );
  }

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  factory BodyStats.fromJson(Map<String, dynamic> json) {
    final historyJson = (json['weightHistory'] as List<dynamic>? ?? []);
    return BodyStats(
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 175.0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 75.0,
      age: (json['age'] as num?)?.toInt() ?? 25,
      gender: (json['gender'] as String?) ?? 'male',
      activityLevel: (json['activityLevel'] as String?) ?? 'moderate',
      goal: (json['goal'] as String?) ?? 'maintain',
      bodyFatPercent: (json['bodyFatPercent'] as num?)?.toDouble() ?? 0.0,
      phoneNumber: (json['phoneNumber'] as String?) ?? '',
      programStartDate: json['programStartDate'] != null
          ? DateTime.parse(json['programStartDate'] as String)
          : DateTime.now(),
      weightHistory: historyJson
          .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'heightCm': heightCm,
        'weightKg': weightKg,
        'age': age,
        'gender': gender,
        'activityLevel': activityLevel,
        'goal': goal,
        'bodyFatPercent': bodyFatPercent,
        'phoneNumber': phoneNumber,
        'programStartDate': programStartDate.toIso8601String(),
        'weightHistory': weightHistory.map((e) => e.toJson()).toList(),
      };

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  /// Loads BodyStats from Firestore. Returns null if not found.
  static Future<BodyStats?> load() async {
    try {
      final data = await FirestoreService.loadBodyStats();
      if (data == null) return null;
      return BodyStats.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Saves this BodyStats to Firestore.
  Future<void> save() async {
    await FirestoreService.saveBodyStats(toJson());
  }

  /// Returns a sensible default BodyStats instance.
  static BodyStats defaults() {
    return BodyStats(
      heightCm: 175.0,
      weightKg: 75.0,
      age: 25,
      gender: 'male',
      activityLevel: 'moderate',
      goal: 'maintain',
      bodyFatPercent: 0.0,
      phoneNumber: '',
      programStartDate: DateTime.now(),
      weightHistory: [],
    );
  }
}
