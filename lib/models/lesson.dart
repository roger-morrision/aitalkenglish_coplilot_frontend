class Lesson {
  final int? id;
  final String title;
  final String description;
  final DateTime scheduledAt;
  final bool completed;
  final String difficulty;
  final String topic;
  final String skillType;
  final int estimatedDuration; // in minutes
  final double rating;
  final int completedBy;

  Lesson({
    this.id, 
    required this.title, 
    required this.description, 
    required this.scheduledAt, 
    this.completed = false,
    this.difficulty = 'Intermediate',
    this.topic = 'General',
    this.skillType = 'All Skills',
    this.estimatedDuration = 15,
    this.rating = 4.0,
    this.completedBy = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'scheduledAt': scheduledAt.toIso8601String(),
    'completed': completed ? 1 : 0,
    'difficulty': difficulty,
    'topic': topic,
    'skillType': skillType,
    'estimatedDuration': estimatedDuration,
    'rating': rating,
    'completedBy': completedBy,
  };

  static Lesson fromMap(Map<String, dynamic> map) => Lesson(
    id: map['id'],
    title: map['title'],
    description: map['description'],
    scheduledAt: DateTime.parse(map['scheduledAt']),
    completed: map['completed'] == 1,
    difficulty: map['difficulty'] ?? 'Intermediate',
    topic: map['topic'] ?? 'General',
    skillType: map['skillType'] ?? 'All Skills',
    estimatedDuration: map['estimatedDuration'] ?? 15,
    rating: (map['rating'] ?? 4.0).toDouble(),
    completedBy: map['completedBy'] ?? 0,
  );
}
