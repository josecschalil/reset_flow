import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:reset_flow/providers/goal_provider.dart';
import 'package:reset_flow/theme/app_theme.dart';
import 'package:reset_flow/models/goal.dart';

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
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }
    
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one day'),
          backgroundColor: AppTheme.dangerColor,
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
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Goal' : 'Create New Goal', style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentColor.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(color: AppTheme.accentColor.withOpacity(0.1), blurRadius: 100, spreadRadius: 50),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: AppTheme.glassShadows(),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: GlassmorphicContainer(
                  width: double.infinity,
                  height: 580,
                  borderRadius: 24,
                  blur: 25,
                  alignment: Alignment.center,
                  border: 1.5,
                  linearGradient: AppTheme.glassLinearGradient(),
                  borderGradient: AppTheme.glassBorderGradient(),
                  child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Goal Details",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'What do you want to achieve?',
                          labelStyle: const TextStyle(color: AppTheme.textSecondary),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.textSecondary.withOpacity(0.3)),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.accentColor, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        "Goal Type",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textPrimary,
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
                      const SizedBox(height: 36),
                      Text(
                        "Active Days",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (index) {
                          final dayNum = index + 1;
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
                                color: isSelected ? AppTheme.accentColor : Colors.white,
                                border: Border.all(
                                  color: isSelected ? AppTheme.accentColor : AppTheme.textSecondary.withOpacity(0.2),
                                  width: 1.5,
                                ),
                                boxShadow: isSelected ? [BoxShadow(color: AppTheme.accentColor.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)] : [],
                              ),
                              child: Center(
                                child: Text(
                                  _weekdays[index],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _saveGoal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor: AppTheme.accentColor.withOpacity(0.5),
                          ),
                          child: Text(isEditing ? 'Update Goal' : 'Create Goal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildTypeButton(String title, String subtitle, bool isAction) {
    final isSelected = _isActionBased == isAction;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isActionBased = isAction;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.accentColor : AppTheme.textSecondary.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: isSelected ? [BoxShadow(color: AppTheme.accentColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppTheme.accentColor : AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
