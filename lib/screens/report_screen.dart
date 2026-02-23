import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reset_flow/providers/goal_provider.dart';
import 'package:reset_flow/models/goal.dart';
import 'package:reset_flow/models/daily_log.dart';
import 'package:flutter/services.dart';
import 'package:reset_flow/utils/streak_calculator.dart';
import 'package:reset_flow/screens/add_goal_screen.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  @override
  Widget build(BuildContext context) {
    final goalState = ref.watch(goalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Goals",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: goalState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSummaryCards(goalState),
                      const SizedBox(height: 32),
                      Text(
                        "Today's Goals",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildAddGoalCard(context),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: _buildGoalsList(goalState),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
    );
  }

  Widget _buildSummaryCards(GoalState state) {
    int totalCompleted =
        state.allLogs.where((l) => l.status == 'completed').length;
    int totalFailed = state.allLogs.where((l) => l.status == 'failed').length;

    return Row(
      children: [
        Expanded(
            child: _buildSummaryCard(
                "Completed", "$totalCompleted", Colors.green)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildSummaryCard("Missed/Failed", "$totalFailed",
                Theme.of(context).colorScheme.error)),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color accentColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: accentColor)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsList(GoalState goalState) {
    if (goalState.todayLogs.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 16.0),
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(Icons.auto_awesome,
                          color: Theme.of(context).colorScheme.primary,
                          size: 40),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "No Goals Yet",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Tap the button above to start building momentum.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SliverReorderableList(
      itemCount: goalState.todayLogs.length,
      onReorder: (oldIndex, newIndex) {
        ref.read(goalProvider.notifier).reorderGoals(oldIndex, newIndex);
      },
      proxyDecorator: (Widget child, int index, Animation<double> animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            final double animValue =
                Curves.easeInOut.transform(animation.value);
            final double elevation = lerpDouble(0, 6, animValue)!;
            return Material(
              elevation: elevation,
              color: Colors.transparent,
              shadowColor: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              child: child,
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
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
        return ReorderableDelayedDragStartListener(
          key: ValueKey(log.id),
          index: index,
          child: _buildGoalCard(context, goal, log),
        );
      },
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
            return await _showDeleteConfirmDialog(context, goal);
          } else if (direction == DismissDirection.startToEnd) {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AddGoalScreen(goalToEdit: goal)),
            );
            return false;
          }
          return false;
        },
        background: _buildSwipeBackground(Icons.edit,
            Theme.of(context).colorScheme.primary, Alignment.centerLeft),
        secondaryBackground: _buildSwipeBackground(Icons.delete,
            Theme.of(context).colorScheme.error, Alignment.centerRight),
        child: Card(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: goal.isActionBased
                ? _buildActionGoal(goal, log, isCompleted)
                : _buildAvoidanceGoal(goal, log, isFailed, isPending),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakPill(Goal goal) {
    // One-time goals don't have streaks
    if (goal.isOneTime) return const SizedBox.shrink();

    final state = ref.read(goalProvider);
    final goalLogs = state.allLogs.where((l) => l.goalId == goal.id).toList();
    final streak = StreakCalculator.calculateCurrentStreak(goal, goalLogs);

    if (streak == 0) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up_rounded,
            size: 12,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '$streak-day streak',
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeBackground(
      IconData icon, Color color, Alignment alignment) {
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
        content: Text(
            'Are you sure you want to permanently delete "${goal.title}" and its logs?'),
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
            child: Text('Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary),
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
            MaterialPageRoute(
                builder: (context) => AddGoalScreen(goalToEdit: goal)),
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
              Icon(Icons.delete,
                  color: Theme.of(context).colorScheme.error, size: 18),
              SizedBox(width: 8),
              Text('Delete',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvoidanceGoal(
      Goal goal, DailyLog log, bool isFailed, bool isPending) {
    final progress = ref.read(goalProvider.notifier).getAvoidanceProgress();

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
                style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error),
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
              style: TextStyle(
                  fontSize: 14,
                  color: isFailed
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: isFailed ? 0 : progress,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(
            isFailed
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildAddGoalCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddGoalScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                "Add New Goal",
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
