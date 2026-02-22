import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reset_flow/providers/goal_provider.dart';
import 'package:reset_flow/theme/app_theme.dart';
import 'package:reset_flow/models/goal.dart';
import 'package:flutter/cupertino.dart';

class AddGoalScreen extends ConsumerStatefulWidget {
  final Goal? goalToEdit;
  
  const AddGoalScreen({super.key, this.goalToEdit});

  @override
  ConsumerState<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends ConsumerState<AddGoalScreen> {
  final _titleController = TextEditingController();
  bool _isActionBased = true;
  Set<int> _selectedDays = {1, 2, 3, 4, 5, 6, 7}; // All days by default

  final List<String> _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    if (widget.goalToEdit != null) {
      _titleController.text = widget.goalToEdit!.title;
      _isActionBased = widget.goalToEdit!.isActionBased;
      _selectedDays = widget.goalToEdit!.activeDays.toSet();
    }
  }

  void _saveGoal() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a goal title'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one day'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (widget.goalToEdit != null) {
      final updatedGoal = Goal(
        id: widget.goalToEdit!.id,
        title: _titleController.text.trim(),
        isActionBased: _isActionBased,
        activeDays: _selectedDays.toList()..sort(),
        createdAt: widget.goalToEdit!.createdAt,
      );
      ref.read(goalProvider.notifier).updateGoal(updatedGoal);
    } else {
      ref.read(goalProvider.notifier).addGoal(
          _titleController.text.trim(),
          _isActionBased,
          _selectedDays.toList()..sort(),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goalToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Goal' : 'Create New Goal'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Goal Details",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'What do you want to achieve?',
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Goal Type",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeButton('Action', 'Hit Gym, Read, etc.', true),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTypeButton('Continuous', 'No Junk, No TV', false),
                          ),
                        ],
                      ),
              const SizedBox(height: 32),
              Text(
                "Active Days",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: List.generate(7, (index) {
                  final dayNum = index + 1;
                  final isSelected = _selectedDays.contains(dayNum);
                  return FilterChip(
                    label: Text(_weekdays[index]),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedDays.add(dayNum);
                        } else {
                          _selectedDays.remove(dayNum);
                        }
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveGoal,
                  child: Text(isEditing ? 'Update Goal' : 'Create Goal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String title, String subtitle, bool isAction) {
    final isSelected = _isActionBased == isAction;
    return ChoiceChip(
      label: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _isActionBased = isAction;
          });
        }
      },
    );
  }
}
