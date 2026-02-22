import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reset_flow/models/due.dart';
import 'package:reset_flow/providers/due_provider.dart';
import 'package:reset_flow/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
      appBar: AppBar(
        title: const Text('Upcoming Deadlines', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: dues.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(Icons.calendar_today_outlined, color: Theme.of(context).colorScheme.primary, size: 40),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "No Deadlines",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "You're all caught up on your hard tasks.",
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: dues.length,
                itemBuilder: (context, index) {
                  return _buildDueCard(dues[index]);
                },
              ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddEditDialog(context, null),
      ),
    );
  }

  Widget _buildDueCard(Due due) {
    final isOverdue = due.deadline.isBefore(DateTime.now()) && !due.isCompleted;
    final formatter = DateFormat('MMM dd, yyyy - hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Checkbox(
          value: due.isCompleted,
          onChanged: (val) {
             ref.read(dueProvider.notifier).toggleDueCompletion(due);
          },
        ),
        title: Text(
          due.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: due.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          formatter.format(due.deadline),
          style: TextStyle(
            color: isOverdue ? Theme.of(context).colorScheme.error : null,
            fontWeight: isOverdue ? FontWeight.bold : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _showAddEditDialog(context, due),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => ref.read(dueProvider.notifier).deleteDue(due.id),
            ),
          ],
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
              title: Text(existingDue == null ? 'New Deadline' : 'Edit Deadline'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Task Description'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
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
                  child: const Text('Cancel'),
                ),
                TextButton(
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
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
