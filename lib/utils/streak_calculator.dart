import 'package:reset_flow/models/daily_log.dart';
import 'package:reset_flow/models/goal.dart';
import 'package:intl/intl.dart';

class StreakCalculator {
  /// Calculates the current streak for a given goal based on its log history.
  static int calculateCurrentStreak(Goal goal, List<DailyLog> logs) {
    if (logs.isEmpty) return 0;
    
    // Sort logs descending by date
    final sortedLogs = List<DailyLog>.from(logs)
      ..sort((a, b) => b.date.compareTo(a.date));

    int currentStreak = 0;
    
    final formatter = DateFormat('yyyy-MM-dd');
    DateTime dateToCheck = DateTime.now();

    for (var i = 0; i < 365; i++) { // Max check a year back to prevent infinite loop
      // Skip days where the goal is not active
      if (!goal.activeDays.contains(dateToCheck.weekday)) {
        dateToCheck = dateToCheck.subtract(const Duration(days: 1));
        continue;
      }

      String dateString = formatter.format(dateToCheck);
      
      // Find log for this day
      final dailyLog = sortedLogs.where((l) => l.date == dateString).firstOrNull;
      
      if (dailyLog == null) {
        // If it's today and log doesn't exist, we just don't count it as a break yet if it's not over.
        // However our app generates logs for today when loaded. So a missing log means it wasn't opened.
        final now = DateTime.now();
        if (dateToCheck.day == now.day && dateToCheck.month == now.month) {
           dateToCheck = dateToCheck.subtract(const Duration(days: 1));
           continue;
        } else {
           // Past missed day breaks streak
           break;
        }
      }

      final status = dailyLog.status;
      
      if (status == 'completed') {
        currentStreak++;
      } else if (status == 'pending') {
         final now = DateTime.now();
         if (dateToCheck.day == now.day && dateToCheck.month == now.month && dateToCheck.year == now.year) {
           // Today is pending. Doesn't break streak, but doesn't add to it.
         } else {
           // A past day left pending breaks streak
           break;
         }
      } else if (status == 'failed') {
        break; // Streak broken
      }

      dateToCheck = dateToCheck.subtract(const Duration(days: 1));
    }

    return currentStreak;
  }
}
