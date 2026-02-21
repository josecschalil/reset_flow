import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:reset_flow/providers/goal_provider.dart';
import 'package:reset_flow/theme/app_theme.dart';
import 'package:reset_flow/screens/add_goal_screen.dart';
import 'package:reset_flow/screens/focus_mode_screen.dart';
import 'package:reset_flow/models/goal.dart';
import 'package:reset_flow/models/daily_log.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:reset_flow/utils/quotes.dart';
import 'package:reset_flow/utils/streak_calculator.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final goalState = ref.watch(goalProvider);

    int completedToday = goalState.todayLogs.where((l) => l.status == 'completed').length;
    int failedToday = goalState.todayLogs.where((l) => l.status == 'failed').length;
    int totalToday = goalState.todayLogs.length;
    double successRate = totalToday == 0 ? 0 : (completedToday / totalToday) * 100;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          // Background Gradient Orbs (Light Mode)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentColor.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(color: AppTheme.accentColor.withOpacity(0.15), blurRadius: 100, spreadRadius: 50),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentSecondary.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(color: AppTheme.accentSecondary.withOpacity(0.1), blurRadius: 100, spreadRadius: 50),
                ],
              ),
            ),
          ),
          SafeArea(
            child: goalState.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
                : CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(24.0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildHeader(),
                            const SizedBox(height: 24),
                            _buildAnalyticsDashboard(successRate.toInt(), completedToday, failedToday, goalState),
                            const SizedBox(height: 32),
                            Text(
                              "Today's Goals",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 16),
                          ]),
                        ),
                      ),
                      goalState.todayLogs.isEmpty
                          ? SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Text(
                                  "No goals for today.\nTap + to create one!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final log = goalState.todayLogs[index];
                                    final goal = goalState.goals.firstWhere(
                                      (g) => g.id == log.goalId,
                                      orElse: () => Goal(
                                        id: '',
                                        title: 'Unknown',
                                        isActionBased: true,
                                        activeDays: [],
                                        createdAt: DateTime.now(),
                                      ),
                                    );
                                    return _buildGoalCard(context, goal, log);
                                  },
                                  childCount: goalState.todayLogs.length,
                                ),
                              ),
                            ),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom padding for FAB
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accentColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddGoalScreen()),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ResetFlow",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: -1,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Beat Procrastination",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            IconButton(
               icon: const Icon(Icons.center_focus_strong, size: 28, color: AppTheme.accentSecondary),
               tooltip: 'Deep Focus Mode',
               onPressed: () {
                 Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FocusModeScreen()),
                 );
               },
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.format_quote, color: AppTheme.accentColor, size: 20),
                  SizedBox(width: 8),
                  Text("DAILY MINDSET", style: TextStyle(color: AppTheme.accentColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                DailyQuotes.todaysQuote,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsDashboard(int successRate, int completed, int failed, GoalState state) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 240, // Expanded for chart + summary
      borderRadius: 24,
      blur: 25,
      alignment: Alignment.center,
      border: 1.5,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.cardColor.withOpacity(0.8), AppTheme.cardColor.withOpacity(0.4)],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withOpacity(0.8), Colors.white.withOpacity(0.1)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem("Success", "$successRate%", AppTheme.accentColor),
                _buildStatItem("Completed", "$completed", AppTheme.successColor),
                _buildStatItem("Missed", "$failed", AppTheme.dangerColor),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 10,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const style = TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 10);
                          const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          if (value.toInt() >= 0 && value.toInt() < 7) {
                            return SideTitleWidget(axisSide: meta.axisSide, child: Text(days[value.toInt()], style: style));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _makeGroupData(0, 5, 2),
                    _makeGroupData(1, 6, 1),
                    _makeGroupData(2, 4, 3),
                    _makeGroupData(3, 7, 0),
                    _makeGroupData(4, 5, 2),
                    _makeGroupData(5, 2, 4),
                    _makeGroupData(6, completed.toDouble(), failed.toDouble()), // Today
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  BarChartGroupData _makeGroupData(int x, double completed, double failed) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: completed,
          color: AppTheme.successColor,
          width: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
        BarChartRodData(
          toY: failed,
          color: AppTheme.dangerColor.withOpacity(0.8),
          width: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildGoalCard(BuildContext context, Goal goal, DailyLog log) {
    if (goal.id.isEmpty) return const SizedBox.shrink();

    final isCompleted = log.status == 'completed';
    final isFailed = log.status == 'failed';
    final isPending = log.status == 'pending';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Dismissible(
        key: Key(log.id),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            // Delete
            return await _showDeleteConfirmDialog(context, goal);
          } else if (direction == DismissDirection.startToEnd) {
             // Edit Goal View (Does not dismiss row)
             Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddGoalScreen(goalToEdit: goal)),
             );
             return false;
          }
          return false;
        },
        background: _buildSwipeBackground(Icons.edit, AppTheme.accentColor, Alignment.centerLeft),
        secondaryBackground: _buildSwipeBackground(Icons.delete, AppTheme.dangerColor, Alignment.centerRight),
        child: GlassmorphicContainer(
          width: double.infinity,
          height: goal.isActionBased ? 120 : 160,
          borderRadius: 20,
          blur: 20,
          alignment: Alignment.center,
          border: 1.5,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.cardColor.withOpacity(0.9),
              AppTheme.cardColor.withOpacity(0.6),
            ],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.8),
              Colors.white.withOpacity(0.2),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
            child: goal.isActionBased
                ? _buildActionGoal(goal, log, isCompleted)
                : _buildAvoidanceGoal(goal, log, isFailed, isPending),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakPill(Goal goal) {
    final state = ref.read(goalProvider);
    final goalLogs = state.allLogs.where((l) => l.goalId == goal.id).toList();
    final streak = StreakCalculator.calculateCurrentStreak(goal, goalLogs);
    
    if (streak == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.4)),
      ),
      child: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
            const Text("🔥", style: TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text("$streak Day Streak", style: const TextStyle(color: AppTheme.accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
         ],
      ),
    );
  }

  Widget _buildSwipeBackground(IconData icon, Color color, Alignment alignment) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(icon, color: color, size: 30),
    );
  }

  Future<bool?> _showDeleteConfirmDialog(BuildContext context, Goal goal) {
     return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.backgroundLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Goal?', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to permanently delete "${goal.title}" and its logs?', style: const TextStyle(color: AppTheme.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
               style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
               onPressed: () {
                 ref.read(goalProvider.notifier).deleteGoal(goal.id);
                 Navigator.pop(context, true);
               },
               child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
  }

  Widget _buildActionGoal(Goal goal, DailyLog log, bool isCompleted) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                goal.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text(
                    "Action Goal",
                    style: TextStyle(fontSize: 12, color: AppTheme.accentColor, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  _buildStreakPill(goal),
                ],
              ),
            ],
          ),
        ),
        if (isCompleted)
           IconButton(
             icon: const Icon(Icons.undo, color: AppTheme.textSecondary, size: 24),
             tooltip: 'Unmark',
             onPressed: () => ref.read(goalProvider.notifier).unmarkActionComplete(log.id),
           ),
        GestureDetector(
          onTap: () {
            if (!isCompleted) {
              ref.read(goalProvider.notifier).markActionComplete(log.id);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? AppTheme.successColor : Colors.transparent,
              border: Border.all(
                color: isCompleted ? AppTheme.successColor : AppTheme.textSecondary.withOpacity(0.3),
                width: 2.5,
              ),
              boxShadow: isCompleted ? [BoxShadow(color: AppTheme.successColor.withOpacity(0.4), blurRadius: 10, spreadRadius: 1)] : [],
            ),
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 26)
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildAvoidanceGoal(Goal goal, DailyLog log, bool isFailed, bool isPending) {
    final progress = ref.read(goalProvider.notifier).getAvoidanceProgress();
    
    // Avoidance goals unmark handling: if it's failed, allow unmarking it back to pending.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                goal.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isFailed ? AppTheme.textSecondary : AppTheme.textPrimary,
                  decoration: isFailed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (isFailed)
               IconButton(
                 icon: const Icon(Icons.undo, color: AppTheme.textSecondary, size: 24),
                 tooltip: 'Unmark',
                 onPressed: () => ref.read(goalProvider.notifier).unmarkActionComplete(log.id),
               )
            else if (isPending)
              InkWell(
                onTap: () {
                  ref.read(goalProvider.notifier).markAvoidanceFailed(log.id);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dangerColor.withOpacity(0.5)),
                  ),
                  child: const Text("Mark Fail", style: TextStyle(color: AppTheme.dangerColor, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text("Continuous Limit", style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                _buildStreakPill(goal),
              ],
            ),
            Text(
               isFailed ? "0%" : "${(progress * 100).toInt()}%",
              style: TextStyle(fontSize: 14, color: isFailed ? AppTheme.dangerColor : AppTheme.accentColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: isFailed ? 0 : progress,
            backgroundColor: AppTheme.textSecondary.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              isFailed ? AppTheme.dangerColor : AppTheme.accentColor,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
