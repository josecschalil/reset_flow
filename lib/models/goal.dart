class Goal {
  final String id;
  final String title;
  final bool isActionBased; // true: action based, false: avoidance
  final List<int> activeDays; // 1-7 (Mon-Sun). Empty = one-time
  final DateTime createdAt;
  final int orderIndex;
  final bool isOneTime; // true = single occurrence, no recurrence

  Goal({
    required this.id,
    required this.title,
    required this.isActionBased,
    required this.activeDays,
    required this.createdAt,
    this.orderIndex = 0,
    this.isOneTime = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isActionBased': isActionBased ? 1 : 0,
      'activeDays': activeDays.join(','),
      'createdAt': createdAt.toIso8601String(),
      'orderIndex': orderIndex,
      'isOneTime': isOneTime ? 1 : 0,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      title: map['title'],
      isActionBased: map['isActionBased'] == 1,
      activeDays: (map['activeDays'] as String? ?? '')
          .split(',')
          .where((e) => e.isNotEmpty)
          .map((e) => int.parse(e))
          .toList(),
      createdAt: DateTime.parse(map['createdAt']),
      orderIndex: map['orderIndex'] ?? 0,
      isOneTime: (map['isOneTime'] ?? 0) == 1,
    );
  }
}
