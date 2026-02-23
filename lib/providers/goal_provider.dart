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
      // One-time goals only show on the day they were created
      if (goal.isOneTime) {
        final createdDateStr = DateFormat('yyyy-MM-dd').format(goal.createdAt);
        if (createdDateStr != todayStr) continue; // Not today, skip
        // Check if already completed — don't re-show completed one-time goals
        final existingLogs = await dbHelper.getLogsForGoal(goal.id);
        final alreadyCompleted = existingLogs.any((l) => l.status == 'completed');
        if (alreadyCompleted) continue;
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
      } else if (goal.activeDays.contains(currentWeekday)) {
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

    // Sort goals by orderIndex
    goals.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    // Sort logs by the order of their corresponding goals (using a map for speed and safety)
    final goalOrderMap = {for (var g in goals) g.id: g.orderIndex};
    logs.sort((a, b) {
      final orderA = goalOrderMap[a.goalId] ?? 0;
      final orderB = goalOrderMap[b.goalId] ?? 0;
      return orderA.compareTo(orderB);
    });

    state = state.copyWith(
      goals: goals,
      todayLogs: logs,
      allLogs: allDailyLogs,
      isLoading: false,
    );
  }

  Future<void> addGoal(String title, bool isActionBased, List<int> activeDays, {bool isOneTime = false}) async {
    final goal = Goal(
      id: _uuid.v4(),
      title: title,
      isActionBased: isActionBased,
      activeDays: isOneTime ? [DateTime.now().weekday] : activeDays,
      createdAt: DateTime.now(),
      orderIndex: state.goals.length,
      isOneTime: isOneTime,
    );
    await dbHelper.insertGoal(goal);
    await loadData();
  }

  Future<void> markActionComplete(String logId) async {
    final updatedLogs = state.todayLogs.map<DailyLog>((log) {
      if (log.id == logId) {
        return log.copyWith(status: 'completed', completedAt: DateTime.now());
      }
      return log;
    }).toList();
    
    state = state.copyWith(todayLogs: updatedLogs);
    await dbHelper.updateLogStatus(logId, 'completed', DateTime.now());
    // No full loadData needed here as we updated locally
  }

  Future<void> unmarkActionComplete(String logId) async {
    final updatedLogs = state.todayLogs.map<DailyLog>((log) {
      if (log.id == logId) {
        return log.copyWith(status: 'pending', completedAt: null);
      }
      return log;
    }).toList();
    
    state = state.copyWith(todayLogs: updatedLogs);
    await dbHelper.updateLogStatus(logId, 'pending', null);
  }

  Future<void> markAvoidanceFailed(String logId) async {
    final updatedLogs = state.todayLogs.map<DailyLog>((log) {
      if (log.id == logId) {
        return log.copyWith(status: 'failed', completedAt: DateTime.now());
      }
      return log;
    }).toList();
    
    state = state.copyWith(todayLogs: updatedLogs);
    await dbHelper.updateLogStatus(logId, 'failed', DateTime.now());
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
    final startOfDay = DateTime(now.year, now.month, now.day);
    final elapsed = now.difference(startOfDay).inMilliseconds;
    final total = 24 * 60 * 60 * 1000;
    return elapsed / total;
  }

  /// Returns the average success rate over the last 7 days (0–100).
  double getWeeklySuccessRate() {
    final formatter = DateFormat('yyyy-MM-dd');
    final today = DateTime.now();
    double totalRate = 0;
    int validDays = 0;

    for (int i = 0; i < 7; i++) {
      final day = today.subtract(Duration(days: i));
      final dayString = formatter.format(day);
      final dayLogs = state.allLogs.where((l) => l.date == dayString).toList();
      if (dayLogs.isEmpty) continue;

      final completed = dayLogs.where((l) => l.status == 'completed').length;
      totalRate += (completed / dayLogs.length) * 100;
      validDays++;
    }

    return validDays == 0 ? 0 : totalRate / validDays;
  }

  /// Returns a list of 7 booleans (oldest → today) representing daily success.
  /// true = any completion that day, false = nothing or all failed.
  List<bool> getLast7DayResults() {
    final formatter = DateFormat('yyyy-MM-dd');
    final today = DateTime.now();
    final results = <bool>[];

    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final dayString = formatter.format(day);
      final dayLogs = state.allLogs.where((l) => l.date == dayString).toList();
      if (dayLogs.isEmpty) {
        results.add(false);
      } else {
        final completed = dayLogs.where((l) => l.status == 'completed').length;
        results.add(completed > 0);
      }
    }
    return results;
  }

  /// Returns the highest single-goal streak among all active goals.
  int getBestCurrentStreak() {
    if (state.goals.isEmpty) return 0;
    int best = 0;
    for (final goal in state.goals) {
      final goalLogs = state.allLogs.where((l) => l.goalId == goal.id).toList();
      int streak = 0;
      final formatter = DateFormat('yyyy-MM-dd');
      DateTime dateToCheck = DateTime.now();
      for (int i = 0; i < 365; i++) {
        if (!goal.activeDays.contains(dateToCheck.weekday)) {
          dateToCheck = dateToCheck.subtract(const Duration(days: 1));
          continue;
        }
        final dateString = formatter.format(dateToCheck);
        final log = goalLogs.where((l) => l.date == dateString).firstOrNull;
        if (log == null || log.status == 'failed') break;
        if (log.status == 'completed') streak++;
        dateToCheck = dateToCheck.subtract(const Duration(days: 1));
      }
      if (streak > best) best = streak;
    }
    return best;
  }

  Future<void> reorderGoals(int oldIndex, int newIndex) async {
    final currentLogs = List<DailyLog>.from(state.todayLogs);
    if (oldIndex >= currentLogs.length) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (newIndex >= currentLogs.length) newIndex = currentLogs.length - 1;
    if (newIndex < 0) newIndex = 0;

    // 1. Update todayLogs IMMEDIATELY for UI stability
    final movedLog = currentLogs.removeAt(oldIndex);
    currentLogs.insert(newIndex, movedLog);
    state = state.copyWith(todayLogs: currentLogs);

    // 2. Perform global reordering of the goals list
    final targetGoalId = movedLog.goalId;
    final destinationGoalId = currentLogs[newIndex == oldIndex ? (newIndex == 0 ? 0 : newIndex) : newIndex].goalId; // Just to find insertion point

    final goals = List<Goal>.from(state.goals);
    final absOldIndex = goals.indexWhere((g) => g.id == targetGoalId);
    
    // We want to insert it at its new relative position in the global list
    // Find the goal that is currently at the newIndex in our visible list
    final neighborGoalId = currentLogs[newIndex].id == movedLog.id 
        ? (newIndex > 0 ? currentLogs[newIndex-1].goalId : (newIndex < currentLogs.length - 1 ? currentLogs[newIndex+1].goalId : null))
        : currentLogs[newIndex].goalId;

    if (absOldIndex == -1) return;

    final item = goals.removeAt(absOldIndex);
    
    // Determine new absolute index
    int absNewIndex;
    if (neighborGoalId == null) {
      absNewIndex = 0;
    } else {
      absNewIndex = goals.indexWhere((g) => g.id == neighborGoalId);
      // If we moved it 'after' the neighbor
      if (newIndex > oldIndex) absNewIndex += 1; 
      if (absNewIndex < 0) absNewIndex = 0;
      if (absNewIndex > goals.length) absNewIndex = goals.length;
    }

    goals.insert(absNewIndex, item);

    // Update global state
    state = state.copyWith(goals: goals);

    // 3. Persist to DB
    for (int i = 0; i < goals.length; i++) {
        final updatedGoal = Goal(
          id: goals[i].id,
          title: goals[i].title,
          isActionBased: goals[i].isActionBased,
          activeDays: goals[i].activeDays,
          createdAt: goals[i].createdAt,
          orderIndex: i,
        );
        await dbHelper.updateGoal(updatedGoal);
    }
    
    // 4. Final sync
    await loadData();
  }
}
