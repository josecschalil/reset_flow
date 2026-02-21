import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:reset_flow/models/due.dart';
import 'package:reset_flow/providers/due_provider.dart';
import 'package:reset_flow/theme/app_theme.dart';
import 'package:intl/intl.dart';

class DuesScreen extends ConsumerStatefulWidget {
  const DuesScreen({super.key});

  @override
  ConsumerState<DuesScreen> createState() => _DuesScreenState();
}

class _DuesScreenState extends ConsumerState<DuesScreen> {
  @override
  Widget build(BuildContext context) {
    final dues = ref.watch(dueProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Upcoming Deadlines', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: dues.isEmpty
          ? const Center(
              child: Text(
                "No deadlines set.\nTap + to add a due date.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24.0),
              itemCount: dues.length,
              itemBuilder: (context, index) {
                final due = dues[index];
                return _buildDueCard(due);
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accentColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddEditDialog(context, null),
      ),
    );
  }

  Widget _buildDueCard(Due due) {
    final isOverdue = due.deadline.isBefore(DateTime.now()) && !due.isCompleted;
    final formatter = DateFormat('MMM dd, yyyy - hh:mm a');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: AppTheme.glassShadows(),
          borderRadius: BorderRadius.circular(24),
        ),
        child: GlassmorphicContainer(
          width: double.infinity,
          height: 100,
          borderRadius: 24,
          blur: 20,
          alignment: Alignment.center,
          border: 1.5,
          linearGradient: due.isCompleted
              ? LinearGradient(colors: [AppTheme.successColor.withOpacity(0.05), AppTheme.successColor.withOpacity(0.02)])
              : AppTheme.glassLinearGradient(),
          borderGradient: AppTheme.glassBorderGradient(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => ref.read(dueProvider.notifier).toggleDueCompletion(due),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: due.isCompleted ? AppTheme.successColor : Colors.transparent,
                      border: Border.all(
                        color: due.isCompleted ? AppTheme.successColor : AppTheme.textSecondary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: due.isCompleted ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        due.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: due.isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary,
                          decoration: due.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatter.format(due.deadline),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOverdue ? AppTheme.dangerColor : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.textSecondary),
                      onPressed: () => _showAddEditDialog(context, due),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.dangerColor),
                      onPressed: () => ref.read(dueProvider.notifier).deleteDue(due.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, Due? existingDue) {
    final titleController = TextEditingController(text: existingDue?.title ?? '');
    DateTime selectedDate = existingDue?.deadline ?? DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.backgroundLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(existingDue == null ? 'New Deadline' : 'Edit Deadline', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'Task Description'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMM dd, yyyy').format(selectedDate), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () async {
                           final picked = await showDatePicker(
                             context: context,
                             initialDate: selectedDate,
                             firstDate: DateTime.now().subtract(const Duration(days: 365)),
                             lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                           );
                           if (picked != null) {
                             setState(() => selectedDate = picked);
                           }
                        },
                        child: const Text('Change Date'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) return;
                    
                    if (existingDue == null) {
                      ref.read(dueProvider.notifier).addDue(
                        titleController.text.trim(),
                        selectedDate,
                      );
                    } else {
                       final updated = Due(
                         id: existingDue.id,
                         title: titleController.text.trim(),
                         deadline: selectedDate,
                         isCompleted: existingDue.isCompleted,
                         createdAt: existingDue.createdAt,
                       );
                       ref.read(dueProvider.notifier).updateDue(updated);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
