import 'package:uuid/uuid.dart';

class FocusSession {
  final String id;
  final DateTime startTime;
  final int durationMinutes;
  final String status; // 'completed', 'failed'
  final int rating;    // 1(small), 2(medium), 3(large bright star)

  FocusSession({
    String? id,
    required this.startTime,
    required this.durationMinutes,
    required this.status,
    required this.rating,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'status': status,
      'rating': rating,
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    return FocusSession(
      id: map['id'],
      startTime: DateTime.parse(map['startTime']),
      durationMinutes: map['durationMinutes'],
      status: map['status'],
      rating: map['rating'],
    );
  }
}
