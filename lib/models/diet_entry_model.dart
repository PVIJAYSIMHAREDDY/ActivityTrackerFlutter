class DietEntryModel {
  final String id;
  final String name;
  final String mealType;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String date;

  DietEntryModel({
    required this.id,
    required this.name,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.date,
  });

  factory DietEntryModel.fromJson(Map<String, dynamic> json) {
    return DietEntryModel(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      mealType: json['meal_type'] ?? json['mealType'] ?? 'snack',
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      date: json['date'] ?? '',
    );
  }

  factory DietEntryModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return DietEntryModel(
      id: docId,
      name: data['name'] ?? '',
      mealType: data['mealType'] ?? 'snack',
      calories: (data['calories'] ?? 0).toDouble(),
      protein: (data['protein'] ?? 0).toDouble(),
      carbs: (data['carbs'] ?? 0).toDouble(),
      fat: (data['fat'] ?? 0).toDouble(),
      date: data['date'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'mealType': mealType,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'date': date,
  };
}
