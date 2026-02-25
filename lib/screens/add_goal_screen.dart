import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reset_flow/providers/goal_provider.dart';
import 'package:reset_flow/models/goal.dart';

enum _GoalFrequency { oneTime, specificDays }

class AddGoalScreen extends ConsumerStatefulWidget {
  final Goal? goalToEdit;

  const AddGoalScreen({super.key, this.goalToEdit});

  @override
  ConsumerState<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends ConsumerState<AddGoalScreen> {
  static const _brand = Color(0xFF5C35C2);

  final _titleController = TextEditingController();
  bool _isActionBased = true;
  _GoalFrequency _frequency = _GoalFrequency.specificDays;
  Set<int> _selectedDays = {1, 2, 3, 4, 5, 6, 7};

  final List<String> _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    if (widget.goalToEdit != null) {
      final g = widget.goalToEdit!;
      _titleController.text = g.title;
      _isActionBased = g.isActionBased;
      if (g.isOneTime) {
        _frequency = _GoalFrequency.oneTime;
      } else {
        _frequency = _GoalFrequency.specificDays;
        _selectedDays = g.activeDays.toSet();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _saveGoal() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a goal title'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_frequency == _GoalFrequency.specificDays && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one active day'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final bool isOneTime = _frequency == _GoalFrequency.oneTime;
    final List<int> days = isOneTime ? [DateTime.now().weekday] : (_selectedDays.toList()..sort());

    if (widget.goalToEdit != null) {
      final updatedGoal = Goal(
        id: widget.goalToEdit!.id,
        title: title,
        isActionBased: _isActionBased,
        activeDays: days,
        createdAt: widget.goalToEdit!.createdAt,
        orderIndex: widget.goalToEdit!.orderIndex,
        isOneTime: isOneTime,
      );
      ref.read(goalProvider.notifier).updateGoal(updatedGoal);
    } else {
      ref.read(goalProvider.notifier).addGoal(
        title,
        _isActionBased,
        days,
        isOneTime: isOneTime,
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goalToEdit != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Goal' : 'New Goal',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1A2E)),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade100, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Title ---
            _sectionLabel('GOAL TITLE'),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A2E)),
              decoration: InputDecoration(
                hintText: 'What do you want to accomplish?',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _brand, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),

            const SizedBox(height: 32),

            // --- Goal Type ---
            _sectionLabel('GOAL TYPE'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _typeCard(
                  title: 'Action',
                  subtitle: 'Do something positive',
                  icon: Icons.bolt,
                  isSelected: _isActionBased,
                  onTap: () => setState(() => _isActionBased = true),
                )),
                const SizedBox(width: 14),
                Expanded(child: _typeCard(
                  title: 'Avoid',
                  subtitle: 'Stop a habit',
                  icon: Icons.block,
                  isSelected: !_isActionBased,
                  onTap: () => setState(() => _isActionBased = false),
                )),
              ],
            ),

            const SizedBox(height: 32),

            // --- Frequency ---
            _sectionLabel('FREQUENCY'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _typeCard(
                  title: 'One-Time',
                  subtitle: null,
                  icon: Icons.looks_one,
                  isSelected: _frequency == _GoalFrequency.oneTime,
                  onTap: () => setState(() => _frequency = _GoalFrequency.oneTime),
                )),
                const SizedBox(width: 14),
                Expanded(child: _typeCard(
                  title: 'Recurring',
                  subtitle: null,
                  icon: Icons.repeat,
                  isSelected: _frequency == _GoalFrequency.specificDays,
                  onTap: () => setState(() => _frequency = _GoalFrequency.specificDays),
                )),
              ],
            ),

            // --- Day picker (only for recurring) ---
            if (_frequency == _GoalFrequency.specificDays) ...[
              const SizedBox(height: 32),
              _sectionLabel('ACTIVE DAYS'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final dayNum = i + 1;
                  final isSelected = _selectedDays.contains(dayNum);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected && _selectedDays.length > 1) {
                          _selectedDays.remove(dayNum);
                        } else {
                          _selectedDays.add(dayNum);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? _brand : Colors.white,
                        border: Border.all(
                          color: isSelected ? _brand : Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _weekdayLabels[i],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _shortcutChip('Weekdays', {1, 2, 3, 4, 5}),
                  const SizedBox(width: 10),
                  _shortcutChip('Weekends', {6, 7}),
                  const SizedBox(width: 10),
                  _shortcutChip('All', {1, 2, 3, 4, 5, 6, 7}),
                ],
              ),
            ],

            const SizedBox(height: 48),

            // --- Save button ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _saveGoal,
                child: Text(
                  isEditing ? 'Update Goal' : 'Create Goal',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Colors.grey.shade500,
      ),
    );
  }

  Widget _typeCard({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF9F8FD) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _brand : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? _brand : Colors.grey.shade400, size: 28),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isSelected ? const Color(0xFF1A1A2E) : Colors.grey.shade800)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _shortcutChip(String label, Set<int> days) {
    return GestureDetector(
      onTap: () => setState(() => _selectedDays = {...days}),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
        ),
      ),
    );
  }
}
