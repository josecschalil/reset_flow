import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({super.key});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> with TickerProviderStateMixin {
  // Timer Settings
  int _focusDuration = 25; // minutes
  int _breakDuration = 5;  // minutes
  
  AnimationController? _timerController;
  Timer? _ticker;
  
  int _secondsRemaining = 25 * 60;
  bool _isActive = false;
  bool _isBreak = false;
  int _completedSessions = 0;
  final int _totalSessionsGoal = 4;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(minutes: _focusDuration),
    );
    _secondsRemaining = _focusDuration * 60;
  }

  @override
  void dispose() {
    _timerController?.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  void _startTimer() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isActive = true;
    });
    
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
          // Calculate progress for the arc
          int totalSeconds = (_isBreak ? _breakDuration : _focusDuration) * 60;
          _timerController?.value = 1 - (_secondsRemaining / totalSeconds);
        });
      } else {
        _onSessionComplete();
      }
    });
  }

  void _pauseTimer() {
    HapticFeedback.lightImpact();
    _ticker?.cancel();
    setState(() {
      _isActive = false;
    });
  }

  void _onSessionComplete() {
    _ticker?.cancel();
    HapticFeedback.heavyImpact();
    
    if (!_isBreak) {
      _completedSessions++;
    }

    bool wasBreak = _isBreak;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(wasBreak ? 'Break Over! 🚀' : 'Session Complete! 🎯'),
        content: Text(wasBreak 
          ? 'Ready to get back to work?' 
          : 'Great job! Time for a short break.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleMode();
            },
            child: Text(wasBreak ? 'Start Focus' : 'Start Break'),
          ),
        ],
      ),
    );

    setState(() {
      _isActive = false;
    });
  }

  void _toggleMode() {
    setState(() {
      _isBreak = !_isBreak;
      int nextDuration = _isBreak ? _breakDuration : _focusDuration;
      _secondsRemaining = nextDuration * 60;
      _timerController?.value = 0;
    });
    _startTimer();
  }

  void _resetTimer() {
    HapticFeedback.mediumImpact();
    _ticker?.cancel();
    setState(() {
      _isActive = false;
      _secondsRemaining = (_isBreak ? _breakDuration : _focusDuration) * 60;
      _timerController?.value = 0;
    });
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Timer Settings',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildSettingSlider(
                'Focus Duration', 
                _focusDuration.toDouble(), 
                10, 60, 
                (val) {
                  setModalState(() => _focusDuration = val.toInt());
                  setState(() {
                    _focusDuration = val.toInt();
                    if (!_isActive && !_isBreak) _secondsRemaining = _focusDuration * 60;
                  });
                }
              ),
              const SizedBox(height: 16),
              _buildSettingSlider(
                'Break Duration', 
                _breakDuration.toDouble(), 
                1, 20, 
                (val) {
                  setModalState(() => _breakDuration = val.toInt());
                  setState(() {
                    _breakDuration = val.toInt();
                    if (!_isActive && _isBreak) _secondsRemaining = _breakDuration * 60;
                  });
                }
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Save Settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingSlider(String title, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('${value.toInt()} min', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  String get _formattedTime {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeModeColor = _isBreak ? Colors.green : colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Mode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Session Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalSessionsGoal, (index) {
                bool isCompleted = index < _completedSessions;
                bool isCurrent = index == _completedSessions && !_isBreak;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isCompleted ? themeModeColor : themeModeColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: isCurrent ? Border.all(color: themeModeColor, width: 2) : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(
              _isBreak ? 'RECOVERY' : 'CONCENTRATION',
              style: TextStyle(
                letterSpacing: 4,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: themeModeColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 40),
            
            // Circular Timer
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 280,
                  height: 280,
                  child: CustomPaint(
                    painter: TimerPainter(
                      progress: _timerController?.value ?? 0.0,
                      color: themeModeColor,
                      backgroundColor: themeModeColor.withOpacity(0.1),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      _formattedTime,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w200,
                            fontSize: 72,
                            color: themeModeColor,
                          ),
                    ),
                    Text(
                      _isBreak ? 'Break Time' : 'Focus Time',
                      style: TextStyle(
                        color: themeModeColor.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 60),
            
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSmallActionBtn(Icons.refresh, _resetTimer),
                const SizedBox(width: 32),
                GestureDetector(
                  onTap: _isActive ? _pauseTimer : _startTimer,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: themeModeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: themeModeColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_isBreak) ...[
                  const SizedBox(width: 32),
                  _buildSmallActionBtn(Icons.skip_next, _onSessionComplete),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallActionBtn(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 24),
      ),
    );
  }
}

class TimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  TimerPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);
    const strokeWidth = 10.0;

    // Background Circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress Arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(TimerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
