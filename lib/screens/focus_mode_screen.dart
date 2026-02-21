import 'dart:async';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
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
          backgroundColor: AppTheme.backgroundLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Focus Session Complete 🎯', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          content: const Text('Great work locking in. Take a 5 minute break before your next session.', style: TextStyle(color: AppTheme.textSecondary)),
          actions: [
            ElevatedButton(
               style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
               onPressed: () {
                 Navigator.pop(context);
                 _resetTimer();
               },
               child: const Text('Reset Timer', style: TextStyle(color: Colors.white)),
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
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Deep Focus', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Subtly animated background glow
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Positioned(
                top: MediaQuery.of(context).size.height * 0.2,
                left: MediaQuery.of(context).size.width * 0.1 - (_pulseController.value * 20),
                child: Container(
                  width: 300 + (_pulseController.value * 50),
                  height: 300 + (_pulseController.value * 50),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isActive 
                        ? AppTheme.accentColor.withOpacity(0.1 - (_pulseController.value * 0.05))
                        : AppTheme.accentColor.withOpacity(0.05),
                    boxShadow: [
                      BoxShadow(color: AppTheme.accentColor.withOpacity(0.1), blurRadius: 100, spreadRadius: 50),
                    ],
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                const Text(
                  "Put down your phone.\nStay focused on your task.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 60),
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        blurRadius: 40,
                        spreadRadius: 10,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(150),
                  ),
                  child: GlassmorphicContainer(
                    width: 300,
                    height: 300,
                    borderRadius: 150,
                    blur: 25,
                    alignment: Alignment.center,
                    border: 1.5,
                    linearGradient: AppTheme.glassLinearGradient(),
                    borderGradient: AppTheme.glassBorderGradient(),
                    child: Center(
                      child: Text(
                        _formattedTime,
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          color: _isActive ? AppTheme.accentColor : AppTheme.textPrimary,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_isActive && _secondsRemaining != 1500)
                      GestureDetector(
                        onTap: _resetTimer,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.textSecondary.withOpacity(0.1)),
                          child: const Icon(Icons.refresh, color: AppTheme.textPrimary, size: 32),
                        ),
                      ),
                    if (!_isActive && _secondsRemaining != 1500)
                       const SizedBox(width: 24),
                    GestureDetector(
                      onTap: _toggleTimer,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isActive ? AppTheme.cardColor : AppTheme.accentColor,
                          border: _isActive ? Border.all(color: AppTheme.accentColor, width: 2) : null,
                          boxShadow: !_isActive ? [BoxShadow(color: AppTheme.accentColor.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))] : [],
                        ),
                        child: Icon(
                          _isActive ? Icons.pause : Icons.play_arrow,
                          color: _isActive ? AppTheme.accentColor : Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
