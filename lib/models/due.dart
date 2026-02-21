class Due {
  final String id;
  final String title;
  final DateTime deadline;
  final bool isCompleted;
  final DateTime createdAt;

  Due({
    required this.id,
    required this.title,
    required this.deadline,
    this.isCompleted = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'deadline': deadline.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Due.fromMap(Map<String, dynamic> map) {
    return Due(
      id: map['id'],
      title: map['title'],
      deadline: DateTime.parse(map['deadline']),
      isCompleted: map['isCompleted'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
