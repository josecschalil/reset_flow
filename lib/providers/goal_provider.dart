import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reset_flow/models/goal.dart';
import 'package:reset_flow/models/daily_log.dart';
import 'package:reset_flow/services/database_helper.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

final goalProvider = StateNotifierProvider<GoalNotifier, GoalState>((ref) {
  return GoalNotifier(DatabaseHelper.instance);
});

class GoalState {
  final List<Goal> goals;
  final List<DailyLog> todayLogs;
  final List<DailyLog> allLogs;
  final bool isLoading;

  GoalState({
    this.goals = const [],
    this.todayLogs = const [],
    this.allLogs = const [],
    this.isLoading = false,
  });

  GoalState copyWith({
    List<Goal>? goals,
    List<DailyLog>? todayLogs,
    List<DailyLog>? allLogs,
    bool? isLoading,
  }) {
    return GoalState(
      goals: goals ?? this.goals,
      todayLogs: todayLogs ?? this.todayLogs,
      allLogs: allLogs ?? this.allLogs,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class GoalNotifier extends StateNotifier<GoalState> {
  final DatabaseHelper dbHelper;
  final _uuid = const Uuid();

  GoalNotifier(this.dbHelper) : super(GoalState(isLoading: true)) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    final goals = await dbHelper.getAllGoals();
    
    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    var logs = await dbHelper.getLogsByDate(todayStr);

    // Initialize missing logs for today based on active days
    int currentWeekday = DateTime.now().weekday; // 1 = Mon, 7 = Sun
    
    for (var goal in goals) {
      if (goal.activeDays.contains(currentWeekday)) {
        bool logExists = logs.any((l) => l.goalId == goal.id);
        if (!logExists) {
          final newLog = DailyLog(
            id: _uuid.v4(),
            goalId: goal.id,
            date: todayStr,
            status: 'pending',
          );
          await dbHelper.insertLog(newLog);
          logs.add(newLog);
        }
      }
    }

    var allDailyLogs = await dbHelper.database.then((db) async {
       final maps = await db.query('daily_logs');
       return maps.map((map) => DailyLog.fromMap(map)).toList();
    });

    state = state.copyWith(
      goals: goals,
      todayLogs: logs,
      allLogs: allDailyLogs,
      isLoading: false,
    );
  }

  Future<void> addGoal(String title, bool isActionBased, List<int> activeDays) async {
    final goal = Goal(
      id: _uuid.v4(),
      title: title,
      isActionBased: isActionBased,
      activeDays: activeDays,
      createdAt: DateTime.now(),
    );
    await dbHelper.insertGoal(goal);
    await loadData();
  }

  Future<void> markActionComplete(String logId) async {
    await dbHelper.updateLogStatus(logId, 'completed', DateTime.now());
    await loadData();
  }

  Future<void> unmarkActionComplete(String logId) async {
    await dbHelper.updateLogStatus(logId, 'pending', null);
    await loadData();
  }

  Future<void> markAvoidanceFailed(String logId) async {
    await dbHelper.updateLogStatus(logId, 'failed', DateTime.now());
    await loadData();
  }

  Future<void> deleteGoal(String goalId) async {
    await dbHelper.deleteLogsForGoal(goalId);
    await dbHelper.deleteGoal(goalId);
    await loadData();
  }

  Future<void> updateGoal(Goal updatedGoal) async {
    await dbHelper.updateGoal(updatedGoal);
    await loadData();
  }

  // Helper method for Avoidance Goals: calculate progress depending on time
  double getAvoidanceProgress() {
    final now = DateTime.now();
    // Milliseconds from midnight
    final startOfDay = DateTime(now.year, now.month, now.day);
    final elapsed = now.difference(startOfDay).inMilliseconds;
    final total = 24 * 60 * 60 * 1000;
    return elapsed / total;
  }
}
