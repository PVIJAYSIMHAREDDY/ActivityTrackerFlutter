class WorkoutModel {
  final String id;
  final String type;
  final String? notes;
  final int durationMins;
  final String date;
  final String? label;

  WorkoutModel({
    required this.id,
    required this.type,
    this.notes,
    required this.durationMins,
    required this.date,
    this.label,
  });

  factory WorkoutModel.fromJson(Map<String, dynamic> json) {
    return WorkoutModel(
      id: (json['id'] ?? '').toString(),
      type: json['type'] ?? '',
      notes: json['notes'],
      durationMins: (json['duration_mins'] ?? 0).toInt(),
      date: json['date'] ?? '',
      label: json['label'],
    );
  }

  factory WorkoutModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return WorkoutModel(
      id: docId,
      type: data['type'] ?? '',
      notes: data['notes'],
      durationMins: (data['durationMins'] ?? 0).toInt(),
      date: data['date'] ?? '',
      label: data['label'],
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'notes': notes,
    'durationMins': durationMins,
    'date': date,
    'label': label,
  };
}
