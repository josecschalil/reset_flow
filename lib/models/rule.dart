import 'dart:convert';

class AppRule {
  final String id;
  final String title;
  final List<String> solutions;
  final DateTime createdAt;

  AppRule({
    required this.id,
    required this.title,
    required this.solutions,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'solutions': jsonEncode(solutions),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppRule.fromMap(Map<String, dynamic> map) {
    return AppRule(
      id: map['id'],
      title: map['title'],
      solutions: List<String>.from(jsonDecode(map['solutions'])),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
