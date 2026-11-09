import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reset_flow/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _textOpacity;
  late Animation<double> _textSlide;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();

    // Gentle expansion while remaining visible from frame 0
    _logoScale = Tween<double>(begin: 0.90, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic));

    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _textOpacity = CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn);
    _textSlide = Tween<double>(begin: 10, end: 0)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _textCtrl.forward();
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ));
      }
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF1E3A5F);
    const bg = Color(0xFFF5F6F8); // AppTheme.pageBackground

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Ambient soft glowing orbs for subtle texture
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    brand.withValues(alpha: 0.06),
                    brand.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4A6A94).withValues(alpha: 0.05),
                    const Color(0xFF4A6A94).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Main Center Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _logoCtrl,
                  builder: (context, _) => Transform.scale(
                    scale: _logoScale.value,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: brand.withValues(alpha: 0.06),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.bolt_rounded,
                          color: brand, size: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                AnimatedBuilder(
                  animation: _textCtrl,
                  builder: (context, _) => Opacity(
                    opacity: _textOpacity.value,
                    child: Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: Column(
                        children: [
                          const Text(
                            'ResetFlow',
                            style: TextStyle(
                              color: Color(0xFF14202E),
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'BEAT PROCRASTINATION',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Loader
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _textCtrl,
              builder: (context, _) => Opacity(
                opacity: _textOpacity.value,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.grey.shade300),
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
}
