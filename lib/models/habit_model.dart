class HabitModel {
  final String id, name, icon, lastDoneDate;
  final int streak;
  final List<String> completedDates;
  HabitModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.streak,
    required this.lastDoneDate,
    this.completedDates = const [],
  });

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  bool doneOn(String date) =>
      completedDates.contains(date) || lastDoneDate == date;
  bool get doneToday => doneOn(dateKey(DateTime.now()));

  factory HabitModel.fromJson(Map<String, dynamic> data) =>
      HabitModel.fromFirestore(data, (data['id'] ?? '').toString());
  factory HabitModel.fromFirestore(Map<String, dynamic> data, String docId) =>
      HabitModel(
        id: docId,
        name: data['name'] ?? '',
        icon: data['icon'] ?? '✅',
        streak: (data['streak'] as num? ?? 0).toInt(),
        lastDoneDate: data['lastDoneDate'] ?? '',
        completedDates: List<String>.from(data['completedDates'] ?? []),
      );

  HabitModel toggleDate(String date, {DateTime? now}) {
    final dates = {
      ...completedDates,
      if (lastDoneDate.isNotEmpty) lastDoneDate,
    };
    if (!dates.remove(date)) dates.add(date);
    final sorted = dates.toList()..sort();
    final current = now ?? DateTime.now();
    var cursor = DateTime(current.year, current.month, current.day);
    if (!dates.contains(dateKey(cursor))) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    var count = 0;
    while (dates.contains(dateKey(cursor))) {
      count++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return HabitModel(
      id: id,
      name: name,
      icon: icon,
      streak: count,
      lastDoneDate: sorted.isEmpty ? '' : sorted.last,
      completedDates: sorted,
    );
  }

  HabitModel copyWith({
    String? id,
    String? name,
    String? icon,
    int? streak,
    String? lastDoneDate,
    List<String>? completedDates,
  }) => HabitModel(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    streak: streak ?? this.streak,
    lastDoneDate: lastDoneDate ?? this.lastDoneDate,
    completedDates: completedDates ?? this.completedDates,
  );
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'icon': icon,
    'streak': streak,
    'lastDoneDate': lastDoneDate,
    'completedDates': completedDates,
  };
}
