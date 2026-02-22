import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reset_flow/providers/goal_provider.dart';
import 'package:reset_flow/theme/app_theme.dart';
import 'package:reset_flow/screens/add_goal_screen.dart';
import 'package:reset_flow/screens/focus_mode_screen.dart';
import 'package:reset_flow/models/goal.dart';
import 'package:reset_flow/models/daily_log.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
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

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
            child: goalState.isLoading
                ? const Center(child: CircularProgressIndicator())
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
                                  ),
                            ),
                            const SizedBox(height: 16),
                          ]),
                        ),
                      ),
                      goalState.todayLogs.isEmpty
                          ? SliverFillRemaining(
                              hasScrollBody: false,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                                child: Center(
                                  child: Card(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 36,
                                          backgroundColor: colorScheme.primaryContainer,
                                          child: Icon(Icons.auto_awesome, color: colorScheme.primary, size: 40),
                                        ),
                                        const SizedBox(height: 20),
                                        const Text(
                                          "No Goals Yet",
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          "Tap the + button to start building momentum.",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
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
                                    return AnimationConfiguration.staggeredList(
                                      position: index,
                                      duration: const Duration(milliseconds: 375),
                                      child: SlideAnimation(
                                        verticalOffset: 50.0,
                                        child: FadeInAnimation(
                                          child: _buildGoalCard(context, goal, log),
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: goalState.todayLogs.length,
                                ),
                              ),
                            ),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom padding for FAB
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
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
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Beat Procrastination",
                ),
              ],
            ),
            IconButton(
               icon: const Icon(Icons.timer_outlined, size: 28),
               tooltip: 'Deep Focus Mode',
               onPressed: () {
                 HapticFeedback.lightImpact();
                 Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FocusModeScreen()),
                 );
               },
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.format_quote, color: Theme.of(context).colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text("DAILY MINDSET", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  DailyQuotes.todaysQuote,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsDashboard(int successRate, int completed, int failed, GoalState state) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem("Success", "$successRate%", colorScheme.primary),
                _buildStatItem("Completed", "$completed", Colors.green),
                _buildStatItem("Missed", "$failed", colorScheme.error),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
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
                          const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          if (value.toInt() >= 0 && value.toInt() < 7) {
                            return SideTitleWidget(axisSide: meta.axisSide, child: Text(days[value.toInt()]));
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
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  BarChartGroupData _makeGroupData(int x, double completed, double failed) {
    final colorScheme = Theme.of(context).colorScheme;
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: completed,
          color: Colors.green,
          width: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
        BarChartRodData(
          toY: failed,
          color: colorScheme.error.withOpacity(0.8),
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
             HapticFeedback.lightImpact();
             Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddGoalScreen(goalToEdit: goal)),
             );
             return false;
          }
          return false;
        },
        background: _buildSwipeBackground(Icons.edit, Theme.of(context).colorScheme.primary, Alignment.centerLeft),
        secondaryBackground: _buildSwipeBackground(Icons.delete, Theme.of(context).colorScheme.error, Alignment.centerRight),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
            const Text("🔥", style: TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text("$streak Days", style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontSize: 11, fontWeight: FontWeight.bold)),
         ],
      ),
    );
  }

  Widget _buildSwipeBackground(IconData icon, Color color, Alignment alignment) {
    return Container(
      color: color.withOpacity(0.1),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Future<bool?> _showDeleteConfirmDialog(BuildContext context, Goal goal) {
     return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Goal?'),
          content: Text('Are you sure you want to permanently delete "${goal.title}" and its logs?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
               onPressed: () {
                 ref.read(goalProvider.notifier).deleteGoal(goal.id);
                 Navigator.pop(context, true);
               },
               child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    "Action",
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 8),
                  _buildStreakPill(goal),
                ],
              ),
            ],
          ),
        ),
        Checkbox(
          value: isCompleted,
          onChanged: (val) {
            if (val == true) {
              ref.read(goalProvider.notifier).markActionComplete(log.id);
            } else {
              ref.read(goalProvider.notifier).unmarkActionComplete(log.id);
            }
          },
        ),
        _buildGoalOptionsMenu(context, goal),
      ],
    );
  }

  Widget _buildGoalOptionsMenu(BuildContext context, Goal goal) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (value) async {
        if (value == 'edit') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddGoalScreen(goalToEdit: goal)),
          );
        } else if (value == 'delete') {
          await _showDeleteConfirmDialog(context, goal);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Theme.of(context).colorScheme.error, size: 18),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: isFailed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (isFailed)
              TextButton.icon(
                onPressed: () {
                  ref.read(goalProvider.notifier).unmarkActionComplete(log.id);
                },
                icon: const Icon(Icons.undo, size: 18),
                label: const Text("Reset"),
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              )
            else if (isPending)
              OutlinedButton(
                onPressed: () {
                  ref.read(goalProvider.notifier).markAvoidanceFailed(log.id);
                },
                child: const Text("Mark Fail"),
              ),
            _buildGoalOptionsMenu(context, goal),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text("Limit", style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                _buildStreakPill(goal),
              ],
            ),
            Text(
               isFailed ? "0%" : "${(progress * 100).toInt()}%",
              style: TextStyle(fontSize: 14, color: isFailed ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: isFailed ? 0 : progress,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(
            isFailed ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
