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
  final _titleController = TextEditingController();
  bool _isActionBased = true;
  _GoalFrequency _frequency = _GoalFrequency.specificDays;
  Set<int> _selectedDays = {1, 2, 3, 4, 5, 6, 7};

  final List<String> _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Goal' : 'New Goal'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Title ---
            _sectionLabel('Goal Title'),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'What do you want to accomplish?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                ),
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 28),

            // --- Goal Type ---
            _sectionLabel('Goal Type'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _typeCard(
                  title: 'Action',
                  subtitle: 'Do something',
                  icon: Icons.bolt_outlined,
                  isSelected: _isActionBased,
                  onTap: () => setState(() => _isActionBased = true),
                )),
                const SizedBox(width: 12),
                Expanded(child: _typeCard(
                  title: 'Avoid',
                  subtitle: 'Stop a habit',
                  icon: Icons.block_outlined,
                  isSelected: !_isActionBased,
                  onTap: () => setState(() => _isActionBased = false),
                )),
              ],
            ),

            const SizedBox(height: 28),

            // --- Frequency ---
            _sectionLabel('Frequency'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _freqCard(
                  title: 'One-Time',
                  subtitle: 'Happens once',
                  icon: Icons.looks_one_outlined,
                  value: _GoalFrequency.oneTime,
                )),
                const SizedBox(width: 12),
                Expanded(child: _freqCard(
                  title: 'Recurring',
                  subtitle: 'On specific days',
                  icon: Icons.repeat_rounded,
                  value: _GoalFrequency.specificDays,
                )),
              ],
            ),

            // --- Day picker (only for recurring) ---
            if (_frequency == _GoalFrequency.specificDays) ...[
              const SizedBox(height: 24),
              _sectionLabel('Active Days'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final dayNum = i + 1;
                  final isSelected = _selectedDays.contains(dayNum);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedDays.remove(dayNum);
                        } else {
                          _selectedDays.add(dayNum);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.surfaceVariant.withOpacity(0.5),
                      ),
                      child: Center(
                        child: Text(
                          _weekdayLabels[i][0],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              _buildDayShortcuts(colorScheme),
            ],

            const SizedBox(height: 36),

            // --- Save button ---
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _saveGoal,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isEditing ? 'Update Goal' : 'Create Goal',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
    );
  }

  Widget _typeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withOpacity(0.6)
              : colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.4),
                size: 22),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? colorScheme.primary : colorScheme.onSurface)),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }

  Widget _freqCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required _GoalFrequency value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _frequency == value;
    return GestureDetector(
      onTap: () => setState(() => _frequency = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.secondaryContainer.withOpacity(0.6)
              : colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.secondary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: isSelected ? colorScheme.secondary : colorScheme.onSurface.withOpacity(0.4),
                size: 22),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? colorScheme.secondary : colorScheme.onSurface)),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }

  Widget _buildDayShortcuts(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          _shortcutChip('Weekdays', {1, 2, 3, 4, 5}, colorScheme),
          const SizedBox(width: 8),
          _shortcutChip('Weekends', {6, 7}, colorScheme),
          const SizedBox(width: 8),
          _shortcutChip('All', {1, 2, 3, 4, 5, 6, 7}, colorScheme),
        ],
      ),
    );
  }

  Widget _shortcutChip(String label, Set<int> days, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => setState(() => _selectedDays = {...days}),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.7)),
        ),
      ),
    );
  }
}
