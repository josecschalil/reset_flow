import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reset_flow/providers/goal_provider.dart';
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
  String? _lockedTask;  // persists until next tap
  
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
    // If a task is already locked, clear and let user spin again
    if (_lockedTask != null) {
      setState(() => _lockedTask = null);
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() {
      _isSpinning = true;
      _spinningText = "Analyzing Tasks...";
    });

    final goalState = ref.read(goalProvider);

    // Collect pending action goals for today only
    List<String> validTasks = [];
    for (var log in goalState.todayLogs) {
       if (log.status == 'pending') {
          final goal = goalState.goals.firstWhere((g) => g.id == log.goalId);
          if (goal.isActionBased) {
             validTasks.add(goal.title);
          }
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
    
    // Lock in the choice — persist until next tap
    String selectedTask = validTasks[index];
    setState(() {
       _spinningText = "LOCKED: $selectedTask";
    });

    await Future.delayed(const Duration(milliseconds: 1200));
    
    setState(() {
      _isSpinning = false;
      _spinningText = null;
      _lockedTask = selectedTask;  // stay shown until next tap
    });
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
                    color: _lockedTask != null
                        ? _getMomentumColor().withOpacity(0.25)
                        : _getMomentumColor().withOpacity(0.15),
                    border: Border.all(
                      color: _getMomentumColor().withOpacity(_lockedTask != null ? 0.8 : 0.5),
                      width: _lockedTask != null ? 5 : 4,
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
                          if (_lockedTask != null) ...[
                            Icon(Icons.bolt, size: 28, color: _getMomentumColor()),
                            const SizedBox(height: 8),
                            Text(
                              _lockedTask!,
                              textAlign: TextAlign.center,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'tap to clear',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ] else if (!_isSpinning) ...[
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
           icon: Icon(_lockedTask != null ? Icons.refresh : Icons.casino),
           label: Text(_lockedTask != null ? "Clear & Re-spin" : "Pick for me"),
           style: TextButton.styleFrom(
              foregroundColor: _getMomentumColor(),
           ),
        ),
      ],
    );
  }
}
