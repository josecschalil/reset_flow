import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reset_flow/theme/app_theme.dart';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({super.key});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _timer;
  int _secondsRemaining = 25 * 60; // 25 Min Deep Work
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isActive) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
          });
        } else {
           _timer?.cancel();
           // Vibrate or play completed sound
           setState(() {
             _isActive = false;
           });
           _showCompleteDialog();
        }
      });
    }
    setState(() {
      _isActive = !_isActive;
    });
  }
  
  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _secondsRemaining = 25 * 60;
    });
  }

  void _showCompleteDialog() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Focus Session Complete 🎯'),
          content: const Text('Great work locking in. Take a 5 minute break before your next session.'),
          actions: [
            TextButton(
               onPressed: () {
                 Navigator.pop(context);
                 _resetTimer();
               },
               child: const Text('Reset Timer'),
            ),
          ],
        ),
      );
  }

  String get _formattedTime {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deep Focus'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formattedTime,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _isActive ? Theme.of(context).colorScheme.primary : null,
                  ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isActive && _secondsRemaining != 1500)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 32),
                    onPressed: _resetTimer,
                  ),
                if (!_isActive && _secondsRemaining != 1500)
                   const SizedBox(width: 16),
                FilledButton.tonal(
                  onPressed: _toggleTimer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Icon(_isActive ? Icons.pause : Icons.play_arrow, size: 32),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
