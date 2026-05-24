class MacroGoals {
  final double protein;
  final double carbs;
  final double fat;

  MacroGoals({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory MacroGoals.fromJson(Map<String, dynamic> json) {
    return MacroGoals(
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
    );
  }
}

class Macros {
  final double protein;
  final double carbs;
  final double fat;

  Macros({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory Macros.fromJson(Map<String, dynamic> json) {
    return Macros(
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
    );
  }
}

class SummaryModel {
  final int tasksDone;
  final int tasksTotal;
  final int habitsDone;
  final int habitsTotal;
  final double calories;
  final int workouts;
  final Macros macros;
  final MacroGoals macroGoals;
  final double? weight;

  SummaryModel({
    required this.tasksDone,
    required this.tasksTotal,
    required this.habitsDone,
    required this.habitsTotal,
    required this.calories,
    required this.workouts,
    required this.macros,
    required this.macroGoals,
    this.weight,
  });

  factory SummaryModel.fromJson(Map<String, dynamic> json) {
    return SummaryModel(
      tasksDone: (json['tasks_done'] ?? 0).toInt(),
      tasksTotal: (json['tasks_total'] ?? 0).toInt(),
      habitsDone: (json['habits_done'] ?? 0).toInt(),
      habitsTotal: (json['habits_total'] ?? 0).toInt(),
      calories: (json['calories'] ?? 0).toDouble(),
      workouts: (json['workouts'] ?? 0).toInt(),
      macros: json['macros'] != null
          ? Macros.fromJson(json['macros'])
          : Macros(protein: 0, carbs: 0, fat: 0),
      macroGoals: json['macro_goals'] != null
          ? MacroGoals.fromJson(json['macro_goals'])
          : MacroGoals(protein: 150, carbs: 250, fat: 65),
      weight: json['weight'] != null ? (json['weight']).toDouble() : null,
    );
  }
}
