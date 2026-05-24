class HabitModel {
  final String id;
  final String name;
  final String icon;
  final int streak;
  final String lastDoneDate;

  HabitModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.streak,
    required this.lastDoneDate,
  });

  bool get doneToday {
    final today = DateTime.now();
    final s = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return lastDoneDate == s;
  }

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      icon: json['icon'] ?? '✅',
      streak: (json['streak'] ?? 0).toInt(),
      lastDoneDate: json['lastDoneDate'] ?? '',
    );
  }

  factory HabitModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return HabitModel(
      id: docId,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '✅',
      streak: (data['streak'] ?? 0).toInt(),
      lastDoneDate: data['lastDoneDate'] ?? '',
    );
  }

  HabitModel copyWith({
    String? id,
    String? name,
    String? icon,
    int? streak,
    String? lastDoneDate,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      streak: streak ?? this.streak,
      lastDoneDate: lastDoneDate ?? this.lastDoneDate,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'icon': icon,
    'streak': streak,
    'lastDoneDate': lastDoneDate,
  };
}
