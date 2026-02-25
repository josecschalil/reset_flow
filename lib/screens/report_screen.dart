import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reset_flow/providers/goal_provider.dart';
import 'package:intl/intl.dart';
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
  static const _brand = Color(0xFF5C35C2);

  @override
  Widget build(BuildContext context) {
    final goalState = ref.watch(goalProvider);

    return Scaffold(
      body: goalState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: CustomScrollView(
                slivers: [
                  // ── Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Today's Goals",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1A1A2E))),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('EEEE, MMM d')
                                      .format(DateTime.now()),
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Material(
                            child: InkWell(
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const AddGoalScreen())),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, size: 25, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // ── Stats bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildSummaryBar(goalState),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // ── Section label
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                      child: Text('GOALS',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: Colors.grey.shade400)),
                    ),
                  ),

                  // ── Goal list
                  if (goalState.todayLogs.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _emptyState(),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: _buildGoalsList(goalState),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryBar(GoalState state) {
    int done =
        state.todayLogs.where((l) => l.status == 'completed').length;
    int failed =
        state.todayLogs.where((l) => l.status == 'failed').length;
    int pending = state.todayLogs.length - done - failed;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _statCol('$done', 'DONE', const Color(0xFF2E7D32)),
          _divider(),
          _statCol('$pending', 'PENDING', const Color(0xFF1565C0)),
          _divider(),
          _statCol('$failed', 'MISSED', Colors.red.shade600),
        ],
      ),
    );
  }

  Widget _divider() => Container(
      width: 1, height: 32, color: Colors.grey.shade200);

  Widget _statCol(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome,
                color: _brand, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('No Goals Yet',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            'Tap New Goal to get started',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(GoalState goalState) {
    return SliverReorderableList(
      itemCount: goalState.todayLogs.length,
      onReorder: (oldIndex, newIndex) {
        ref.read(goalProvider.notifier).reorderGoals(oldIndex, newIndex);
      },
      proxyDecorator:
          (Widget child, int index, Animation<double> animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            final double animValue =
                Curves.easeInOut.transform(animation.value);
            final double elevation = lerpDouble(0, 6, animValue)!;
            return Material(
              elevation: elevation,
              color: Colors.transparent,
              shadowColor: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
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
              createdAt: DateTime.now()),
        );
        return ReorderableDelayedDragStartListener(
          key: ValueKey(log.id),
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildGoalCard(goal, log),
          ),
        );
      },
    );
  }

  Widget _buildGoalCard(Goal goal, DailyLog log) {
    if (goal.id.isEmpty) return const SizedBox.shrink();

    final isCompleted = log.status == 'completed';
    final isFailed = log.status == 'failed';
    final isPending = log.status == 'pending';

    return Dismissible(
      key: Key('${log.id}_dismiss'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.lightImpact();
          Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => AddGoalScreen(goalToEdit: goal)));
          return false;
        } else {
          return await _showDeleteConfirmDialog(goal);
        }
      },
      background: _swipeBg(Icons.edit, _brand, Alignment.centerLeft),
      secondaryBackground: _swipeBg(
          Icons.delete, Colors.red.shade600, Alignment.centerRight),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF2E7D32).withOpacity(0.2)
                : isFailed
                    ? Colors.red.withOpacity(0.2)
                    : Colors.grey.shade200,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: goal.isActionBased
              ? _buildActionRow(goal, log, isCompleted)
              : _buildAvoidanceContent(goal, log, isFailed, isPending),
        ),
      ),
    );
  }

  Widget _swipeBg(IconData icon, Color color, Alignment alignment) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildActionRow(Goal goal, DailyLog log, bool isCompleted) {
    return Row(
      children: [
        // Drag handle
        Icon(Icons.drag_indicator,
            color: Colors.grey.shade300, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _chip('ACTION', _brand),
                  const SizedBox(width: 8),
                  _streakPill(goal),
                ],
              ),
              const SizedBox(height: 6),
              Text(goal.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isCompleted
                        ? Colors.grey.shade400
                        : const Color(0xFF1A1A2E),
                    decoration:
                        isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.grey.shade400,
                  )),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Checkbox
        GestureDetector(
          onTap: () {
            if (isCompleted) {
              ref.read(goalProvider.notifier).unmarkActionComplete(log.id);
            } else {
              ref.read(goalProvider.notifier).markActionComplete(log.id);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: isCompleted ? _brand : Colors.transparent,
              border: Border.all(
                color: isCompleted ? _brand : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
        ),
        _goalMenu(goal),
      ],
    );
  }

  Widget _buildAvoidanceContent(
      Goal goal, DailyLog log, bool isFailed, bool isPending) {
    final progress =
        ref.read(goalProvider.notifier).getAvoidanceProgress();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.drag_indicator,
                color: Colors.grey.shade300, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  _chip('LIMIT', Colors.red.shade600),
                  const SizedBox(width: 8),
                  _streakPill(goal),
                ],
              ),
            ),
            _goalMenu(goal),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 30, top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(goal.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isFailed
                        ? Colors.grey.shade400
                        : const Color(0xFF1A1A2E),
                    decoration:
                        isFailed ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.grey.shade400,
                  )),
              if (isFailed)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          size: 14, color: Colors.red.shade600),
                      const SizedBox(width: 4),
                      Text('Limit exceeded',
                          style: TextStyle(
                              color: Colors.red.shade600, fontSize: 12)),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PROGRESS',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: Colors.grey.shade400)),
                  Text(
                    isFailed ? '0%' : '${(progress * 100).toInt()}%',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isFailed
                            ? Colors.red.shade600
                            : _brand),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: isFailed ? 0 : progress,
                  minHeight: 5,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                      isFailed ? Colors.red.shade300 : _brand),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: isFailed
                    ? TextButton(
                        onPressed: () => ref
                            .read(goalProvider.notifier)
                            .unmarkActionComplete(log.id),
                        style: TextButton.styleFrom(
                            foregroundColor: _brand,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6)),
                        child: const Text('Reset',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      )
                    : OutlinedButton(
                        onPressed: () => ref
                            .read(goalProvider.notifier)
                            .markAvoidanceFailed(log.id),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade600,
                            side: BorderSide(
                                color: Colors.red.shade300),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(20))),
                        child: const Text('Mark Fail',
                            style: TextStyle(fontSize: 13)),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
    );
  }

  Widget _streakPill(Goal goal) {
    if (goal.isOneTime) return const SizedBox.shrink();
    final state = ref.read(goalProvider);
    final logs =
        state.allLogs.where((l) => l.goalId == goal.id).toList();
    final streak =
        StreakCalculator.calculateCurrentStreak(goal, logs);
    if (streak == 0) return const SizedBox.shrink();
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department,
              size: 13, color: Colors.orange),
          const SizedBox(width: 3),
          Text('$streak-day streak',
              style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _goalMenu(Goal goal) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert,
          size: 20, color: Colors.grey.shade400),
      onSelected: (value) async {
        if (value == 'edit') {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddGoalScreen(goalToEdit: goal)));
        } else if (value == 'delete') {
          await _showDeleteConfirmDialog(goal);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
            value: 'edit',
            child: Row(children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 8),
              Text('Edit')
            ])),
        PopupMenuItem(
            value: 'delete',
            child: Row(children: [
              Icon(Icons.delete_outline,
                  color: Colors.red.shade600, size: 18),
              const SizedBox(width: 8),
              Text('Delete',
                  style: TextStyle(color: Colors.red.shade600))
            ])),
      ],
    );
  }

  Future<bool?> _showDeleteConfirmDialog(Goal goal) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal?'),
        content:
            Text('Delete "${goal.title}" and all its history?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600),
            onPressed: () {
              ref.read(goalProvider.notifier).deleteGoal(goal.id);
              Navigator.pop(context, true);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
