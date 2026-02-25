import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reset_flow/services/auth_service.dart';
import 'package:reset_flow/screens/main_layout.dart';
import 'package:reset_flow/screens/change_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const _brand = Color(0xFF5C35C2);
  final List<String> _digits = [];
  bool _error = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onDigit(String d) {
    if (_digits.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _digits.add(d);
      _error = false;
    });
    if (_digits.length == 4) _verify();
  }

  void _onDelete() {
    if (_digits.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _digits.removeLast());
  }

  Future<void> _verify() async {
    final ok = await AuthService.verifyPin(_digits.join());
    if (ok) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainLayout(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ));
    } else {
      HapticFeedback.vibrate();
      setState(() => _error = true);
      await _shakeCtrl.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 350));
      setState(() => _digits.clear());
      _shakeCtrl.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Ambient blobs
          Positioned(
            top: -70,
            right: -70,
            child: _blob(220, const Color(0xFFEDE9FB)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _blob(180, const Color(0xFFF3F0FD)),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 52),
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEDE9FB),
                    boxShadow: [
                      BoxShadow(
                        color: _brand.withOpacity(0.15),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.bolt_rounded, color: _brand, size: 40),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome back',
                  style: TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter your PIN to continue',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 48),
                // PIN dots
                AnimatedBuilder(
                  animation: _shakeCtrl,
                  builder: (context, child) {
                    final offset = _error
                        ? 10 *
                            (0.5 - (_shakeAnim.value % 0.25) / 0.25).abs()
                        : 0.0;
                    return Transform.translate(
                        offset: Offset(offset, 0), child: child);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final filled = i < _digits.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled
                              ? (_error ? Colors.red.shade400 : _brand)
                              : Colors.grey.shade200,
                          boxShadow: filled && !_error
                              ? [
                                  BoxShadow(
                                    color: _brand.withOpacity(0.35),
                                    blurRadius: 8,
                                  )
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedOpacity(
                  opacity: _error ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    'Incorrect PIN. Try again.',
                    style: TextStyle(
                        color: Colors.red.shade400, fontSize: 12),
                  ),
                ),
                const Spacer(),
                _buildNumpad(),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen()),
                  ),
                  child: Text(
                    'Change PIN',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.grey.shade400,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpad() {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((k) {
                if (k.isEmpty) return const SizedBox(width: 72, height: 72);
                if (k == 'del') {
                  return _key(
                    onTap: _onDelete,
                    child: Icon(Icons.backspace_outlined,
                        color: Colors.grey.shade600, size: 22),
                    isText: false,
                  );
                }
                return _key(
                  onTap: () => _onDigit(k),
                  child: Text(k,
                      style: const TextStyle(
                          color: Color(0xFF1A1A2E),
                          fontSize: 24,
                          fontWeight: FontWeight.w500)),
                  isText: true,
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _key(
      {required VoidCallback onTap,
      required Widget child,
      required bool isText}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isText ? Colors.grey.shade50 : Colors.transparent,
          border: isText
              ? Border.all(color: Colors.grey.shade200)
              : null,
          boxShadow: isText
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}
