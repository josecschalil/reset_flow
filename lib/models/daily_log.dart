class DailyLog {
  final String id;
  final String goalId;
  final String date; // YYYY-MM-DD format
  final String status; // 'pending', 'completed', 'failed'
  final DateTime? completedAt;

  DailyLog({
    required this.id,
    required this.goalId,
    required this.date,
    required this.status,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalId': goalId,
      'date': date,
      'status': status,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory DailyLog.fromMap(Map<String, dynamic> map) {
    return DailyLog(
      id: map['id'],
      goalId: map['goalId'],
      date: map['date'],
      status: map['status'],
      completedAt: map['completedAt'] != null 
          ? DateTime.parse(map['completedAt']) 
          : null,
    );
  }
}
