class Lesson {
  final int? id;
  final String title;
  final String description;
  final DateTime scheduledAt;
  final bool completed;

  Lesson({this.id, required this.title, required this.description, required this.scheduledAt, this.completed = false});

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'scheduledAt': scheduledAt.toIso8601String(),
    'completed': completed ? 1 : 0,
  };

  static Lesson fromMap(Map<String, dynamic> map) => Lesson(
    id: map['id'],
    title: map['title'],
    description: map['description'],
    scheduledAt: DateTime.parse(map['scheduledAt']),
    completed: map['completed'] == 1,
  );
}
