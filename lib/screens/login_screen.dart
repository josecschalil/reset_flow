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
  static const _brand = Color(0xFF1E3A5F);
  static const _bg = Color(0xFFF5F6F8);
  static const _textDark = Color(0xFF14202E);

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
        vsync: this, duration: const Duration(milliseconds: 500));
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
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ));
    } else {
      HapticFeedback.vibrate();
      setState(() => _error = true);
      await _shakeCtrl.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() => _digits.clear());
      _shakeCtrl.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    // using LayoutBuilder inside SingleChildScrollView fixes overflows
    // on small screens while maintaining layout on larger ones.
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    // Icon
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.lock_rounded,
                          color: _brand, size: 28),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        color: _textDark,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your secure PIN',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    // Spacing that collapses if needed
                    const Spacer(),

                    // PIN dots
                    AnimatedBuilder(
                      animation: _shakeCtrl,
                      builder: (context, child) {
                        final offset = _error
                            ? 12 *
                                (0.5 - (_shakeAnim.value % 0.25) / 0.25).abs()
                            : 0.0;
                        return Transform.translate(
                            offset: Offset(offset, 0), child: child);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (i) {
                            final filled = i < _digits.length;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: filled
                                    ? (_error ? Colors.red.shade400 : _brand)
                                    : Colors.grey.shade200,
                                border: filled
                                    ? null
                                    : Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1.5),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedOpacity(
                      opacity: _error ? 1 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        'Incorrect PIN',
                        style: TextStyle(
                            color: Colors.red.shade400,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),

                    const Spacer(),

                    // Numpad
                    _buildNumpad(),

                    const SizedBox(height: 24),

                    // Change PIN Link
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen()),
                      ),
                      style: TextButton.styleFrom(
                        splashFactory: NoSplash.splashFactory,
                      ),
                      child: Text(
                        'Change PIN',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        }),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((k) {
                if (k.isEmpty) return const SizedBox(width: 64, height: 64);
                if (k == 'del') {
                  return _key(
                    onTap: _onDelete,
                    child: Icon(Icons.backspace_outlined,
                        color: Colors.grey.shade500, size: 22),
                  );
                }
                return _key(
                  onTap: () => _onDigit(k),
                  child: Text(k,
                      style: const TextStyle(
                          color: _textDark,
                          fontSize: 26,
                          fontWeight: FontWeight.w500)),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _key({required VoidCallback onTap, required Widget child}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      highlightColor: Colors.white,
      splashColor: const Color(0xFFEEF2F7),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.5),
        ),
        child: Center(child: child),
      ),
    );
  }
}
