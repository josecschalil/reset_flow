import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reset_flow/providers/goal_provider.dart';
import 'package:reset_flow/providers/due_provider.dart';
import 'package:reset_flow/screens/focus_mode_screen.dart';
import 'dart:async';

class MomentumRoulette extends ConsumerStatefulWidget {
  final double successRate;
  
  const MomentumRoulette({super.key, required this.successRate});

  @override
  ConsumerState<MomentumRoulette> createState() => _MomentumRouletteState();
}

class _MomentumRouletteState extends ConsumerState<MomentumRoulette> with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _scaleAnimation;
  bool _isSpinning = false;
  String? _spinningText;
  
  @override
  void initState() {
    super.initState();
    _setupBreathingAnimation();
  }

  @override
  void didUpdateWidget(MomentumRoulette oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.successRate != widget.successRate) {
      _breathingController.dispose();
      _setupBreathingAnimation();
    }
  }

  void _setupBreathingAnimation() {
    // Determine speed and scale based on momentum (success rate)
    // High success rate = Faster breathing, larger scale, greener color
    // Low success rate = Slower breathing, smaller scale, more orange
    
    int durationMs = 3000;
    if (widget.successRate > 70) {
      durationMs = 1500;
    } else if (widget.successRate > 40) {
      durationMs = 2000;
    } else if (widget.successRate > 0) {
      durationMs = 2500;
    }
    
    _breathingController = AnimationController(
       vsync: this,
       duration: Duration(milliseconds: durationMs),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  Color _getMomentumColor() {
    return Colors.amber;
  }

  void _spinRoulette() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _isSpinning = true;
      _spinningText = "Analyzing Tasks...";
    });

    final goalState = ref.read(goalProvider);
    final duesState = ref.read(dueProvider);

    // Collect all pending tasks
    List<String> validTasks = [];
    
    // Add pending action goals for today
    for (var log in goalState.todayLogs) {
       if (log.status == 'pending') {
          final goal = goalState.goals.firstWhere((g) => g.id == log.goalId);
          if (goal.isActionBased) {
             validTasks.add(goal.title);
          }
       }
    }

    // Add uncompleted dues
    for (var due in duesState) {
       if (!due.isCompleted) {
          validTasks.add(due.title);
       }
    }

    if (validTasks.isEmpty) {
       await Future.delayed(const Duration(seconds: 1));
       setState(() {
         _isSpinning = false;
         _spinningText = null;
       });
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("You are all caught up! No pending tasks.")),
         );
       }
       return;
    }

    // Dramatic roulette effect
    int spins = 20;
    int index = 0;
    Random random = Random();
    
    for (int i = 0; i < spins; i++) {
       index = random.nextInt(validTasks.length);
       setState(() {
          _spinningText = validTasks[index];
       });
       HapticFeedback.lightImpact();
       // Slow down as it gets to the end
       int delay = 50 + (i * i ~/ 2);
       await Future.delayed(Duration(milliseconds: delay));
    }

    HapticFeedback.vibrate();
    
    // Lock in the choice
    String selectedTask = validTasks[index];
    setState(() {
       _spinningText = "LOCKED: $selectedTask";
    });

    await Future.delayed(const Duration(milliseconds: 1500));
    
    setState(() {
      _isSpinning = false;
      _spinningText = null;
    });

    if (mounted) {
       Navigator.push(
         context,
         MaterialPageRoute(
           builder: (context) => FocusModeScreen(taskName: selectedTask),
         ),
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          "Momentum Engine",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          widget.successRate == 0 
           ? "Engine is cold. Fuel it with a task." 
           : "Engine is running. Keep going!",
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: _isSpinning ? null : _spinRoulette,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isSpinning ? 1.0 : _scaleAnimation.value,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getMomentumColor().withOpacity(0.15),
                    border: Border.all(
                      color: _getMomentumColor().withOpacity(0.5),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getMomentumColor().withOpacity(0.3 * (_isSpinning ? 1.0 : _scaleAnimation.value)),
                        blurRadius: 30,
                        spreadRadius: 10,
                      )
                    ]
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!_isSpinning) ...[
                            Icon(Icons.bolt, size: 48, color: _getMomentumColor()),
                            const SizedBox(height: 8),
                            Text(
                              "Focus\nRoulette",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ] else ...[
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              _spinningText ?? "",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        TextButton.icon(
           onPressed: _isSpinning ? null : _spinRoulette,
           icon: const Icon(Icons.casino),
           label: const Text("Pick for me"),
           style: TextButton.styleFrom(
              foregroundColor: _getMomentumColor(),
           ),
        ),
      ],
    );
  }
}
