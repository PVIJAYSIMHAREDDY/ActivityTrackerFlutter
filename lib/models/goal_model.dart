class GoalModel {
  final String id;
  final String title;
  final String category;
  final double targetValue;
  final double currentValue;

  GoalModel({
    required this.id,
    required this.title,
    required this.category,
    required this.targetValue,
    required this.currentValue,
  });

  double get progress => targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;
  bool get isComplete => progress >= 1.0;

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: (json['id'] ?? '').toString(),
      title: json['title'] ?? '',
      category: json['category'] ?? 'personal',
      targetValue: (json['target_value'] ?? json['targetValue'] ?? 0).toDouble(),
      currentValue: (json['current_value'] ?? json['currentValue'] ?? 0).toDouble(),
    );
  }

  factory GoalModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return GoalModel(
      id: docId,
      title: data['title'] ?? '',
      category: data['category'] ?? 'personal',
      targetValue: (data['targetValue'] ?? 0).toDouble(),
      currentValue: (data['currentValue'] ?? 0).toDouble(),
    );
  }

  GoalModel copyWith({
    String? id,
    String? title,
    String? category,
    double? targetValue,
    double? currentValue,
  }) {
    return GoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'category': category,
    'targetValue': targetValue,
    'currentValue': currentValue,
  };
}
