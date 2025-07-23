class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? date;
  final List<String>? tags;
  final String priority; // "Low", "Medium", "High"
  final int order;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.date,
    this.tags,
    required this.priority,
    required this.order,
  });

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'],
        title: map['title'],
        description: map['description'],
        date: map['date'] != null ? DateTime.parse(map['date']) : null,
        tags: (map['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
        priority: map['priority'] ?? 'Low',
        order: map['order'] ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date?.toIso8601String(),
        'tags': tags,
        'priority': priority,
        'order': order,
      };
}
