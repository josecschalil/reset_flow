import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reset_flow/models/due.dart';
import 'package:reset_flow/providers/due_provider.dart';

class DuesScreen extends ConsumerStatefulWidget {
  const DuesScreen({super.key});

  @override
  ConsumerState<DuesScreen> createState() => _DuesScreenState();
}

class _DuesScreenState extends ConsumerState<DuesScreen> {
  static const _brand = Color(0xFF5C35C2);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dueProvider);
    final dues = state;

    final pendingDues = dues.where((d) => !d.isCompleted).toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
    final completedDues = dues.where((d) => d.isCompleted).toList()
      ..sort((a, b) => b.deadline.compareTo(a.deadline));

    final now = DateTime.now();
    int overdueCount = pendingDues.where((d) => d.deadline.isBefore(now)).length;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dues',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A1A2E))),
                          const SizedBox(height: 4),
                          Text('Upcoming deadlines',
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
              
                    
                      child: InkWell(
                        
                        onTap: () => _showAddEditDialog(context, null),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 25, color: Colors.grey),
                              SizedBox(width: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Stats bar
            if (dues.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        _statCol('${pendingDues.length}', 'PENDING', _brand),
                        _divider(),
                        _statCol('${completedDues.length}', 'COMPLETED', const Color(0xFF2E7D32)),
                        _divider(),
                        _statCol('$overdueCount', 'OVERDUE', Colors.red.shade600),
                      ],
                    ),
                  ),
                ),
              ),

            if (dues.isNotEmpty)
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Empty state
            if (dues.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEDE9FB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.event_available,
                                color: _brand, size: 32),
                          ),
                          const SizedBox(height: 16),
                          const Text('All Caught Up!',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text(
                            'No upcoming deadlines right now.',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ── Pending List
            if (pendingDues.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Text('PENDING',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: Colors.grey.shade400)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildDueCard(pendingDues[index]),
                    childCount: pendingDues.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],

            // ── Completed List
            if (completedDues.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Text('COMPLETED',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: Colors.grey.shade400)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildDueCard(completedDues[index]),
                    childCount: completedDues.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 32, color: Colors.grey.shade200);

  Widget _statCol(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
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

  Widget _buildDueCard(Due due) {
    final isOverdue = !due.isCompleted && due.deadline.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox
            GestureDetector(
              onTap: () => ref.read(dueProvider.notifier).toggleDueCompletion(due),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: due.isCompleted ? const Color(0xFF2E7D32) : Colors.transparent,
                  border: Border.all(
                    color: due.isCompleted ? const Color(0xFF2E7D32) : _brand,
                    width: 2,
                  ),
                ),
                child: due.isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        due.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: due.isCompleted ? Colors.grey.shade400 : const Color(0xFF1A1A2E),
                          decoration: due.isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: Colors.grey.shade400,
                        ),
                      ),
                      if (isOverdue)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('OVERDUE',
                              style: TextStyle(
                                  color: Colors.red.shade600,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_filled,
                          size: 14,
                          color: isOverdue ? Colors.red.shade600 : Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(due.deadline),
                        style: TextStyle(
                          fontSize: 13,
                          color: isOverdue ? Colors.red.shade600 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => _showAddEditDialog(context, due),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => ref.read(dueProvider.notifier).deleteDue(due.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade300),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    String dateStr;
    if (target == today) {
      dateStr = 'Today';
    } else if (target == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = DateFormat('MMM dd, yyyy').format(date);
    }
    return '$dateStr • ${DateFormat('h:mm a').format(date)}';
  }

  void _showAddEditDialog(BuildContext context, Due? due) {
    final titleController = TextEditingController(text: due?.title ?? '');
    DateTime selectedDate = due?.deadline ?? DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(due == null ? 'New Deadline' : 'Edit Deadline'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Task Description'),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Due Date & Time', style: TextStyle(fontSize: 14)),
                  subtitle: Text(DateFormat('MMM dd, yyyy • h:mm a').format(selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: _brand)),
                  trailing: TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (date != null) {
                        if (!context.mounted) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDate),
                        );
                        if (time != null) {
                          setState(() {
                            selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                          });
                        }
                      }
                    },
                    child: const Text('Change'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  if (titleController.text.trim().isEmpty) return;
                  if (due == null) {
                    ref.read(dueProvider.notifier).addDue(titleController.text.trim(), selectedDate);
                  } else {
                    ref.read(dueProvider.notifier).updateDue(Due(
                          id: due.id,
                          title: titleController.text.trim(),
                          deadline: selectedDate,
                          isCompleted: due.isCompleted,
                          createdAt: due.createdAt,
                        ));
                  }
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }
}
