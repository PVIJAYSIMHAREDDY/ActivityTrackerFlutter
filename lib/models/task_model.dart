class TaskModel {
  final String id;
  final String text;
  final String priority;
  final bool done;
  final String date;

  TaskModel({
    required this.id,
    required this.text,
    required this.priority,
    required this.done,
    required this.date,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: (json['id'] ?? '').toString(),
      text: json['text'] ?? '',
      priority: json['priority'] ?? 'medium',
      done: json['done'] == true || json['done'] == 1,
      date: json['date'] ?? '',
    );
  }

  factory TaskModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return TaskModel(
      id: docId,
      text: data['text'] ?? '',
      priority: data['priority'] ?? 'medium',
      done: data['done'] == true,
      date: data['date'] ?? '',
    );
  }

  TaskModel copyWith({
    String? id,
    String? text,
    String? priority,
    bool? done,
    String? date,
  }) {
    return TaskModel(
      id: id ?? this.id,
      text: text ?? this.text,
      priority: priority ?? this.priority,
      done: done ?? this.done,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'priority': priority,
    'done': done,
    'date': date,
  };
}
