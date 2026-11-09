import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reset_flow/services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  static const _brand = Color(0xFF1E3A5F);
  static const _bg = Color(0xFFF5F6F8);
  static const _textDark = Color(0xFF14202E);

  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _loading = false;
  String? _errorMsg;
  bool _success = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    final currentOk = await AuthService.verifyPin(_currentCtrl.text.trim());
    if (!currentOk) {
      setState(() {
        _loading = false;
        _errorMsg = 'Current PIN is incorrect.';
      });
      return;
    }

    await AuthService.setPin(_newCtrl.text.trim());
    HapticFeedback.mediumImpact();
    setState(() {
      _loading = false;
      _success = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.pop(context);
  }

  InputDecoration _inp(String label, bool show, VoidCallback toggle) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 13,
          fontWeight: FontWeight.w500),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _brand, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      counterStyle: const TextStyle(fontSize: 0, height: 0),
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: IconButton(
          onPressed: toggle,
          splashRadius: 20,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          icon: Icon(
            show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.grey.shade400,
            size: 20,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: _textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
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
                  child: const Icon(Icons.lock_reset_rounded,
                      color: _brand, size: 26),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Change PIN',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Update your security PIN below.',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _currentCtrl,
                  obscureText: !_showCurrent,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  style: const TextStyle(
                      color: _textDark,
                      fontSize: 18,
                      letterSpacing: 8,
                      fontWeight: FontWeight.w600),
                  decoration: _inp('Current PIN', _showCurrent,
                      () => setState(() => _showCurrent = !_showCurrent)),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (v.trim().length < 4) return 'PIN must be 4 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newCtrl,
                  obscureText: !_showNew,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  style: const TextStyle(
                      color: _textDark,
                      fontSize: 18,
                      letterSpacing: 8,
                      fontWeight: FontWeight.w600),
                  decoration: _inp('New PIN', _showNew,
                      () => setState(() => _showNew = !_showNew)),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (v.trim().length < 4) return 'PIN must be 4 digits';
                    if (v.trim() == _currentCtrl.text.trim()) {
                      return 'New PIN must differ from current';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: !_showConfirm,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  style: const TextStyle(
                      color: _textDark,
                      fontSize: 18,
                      letterSpacing: 8,
                      fontWeight: FontWeight.w600),
                  decoration: _inp('Confirm New PIN', _showConfirm,
                      () => setState(() => _showConfirm = !_showConfirm)),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (v.trim() != _newCtrl.text.trim()) {
                      return 'PINs do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (_errorMsg != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_rounded,
                              color: Colors.red.shade400, size: 20),
                          const SizedBox(width: 8),
                          Text(_errorMsg!,
                              style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                if (_success)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.green.shade500, size: 20),
                          const SizedBox(width: 8),
                          Text('PIN updated successfully!',
                              style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading || _success ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brand,
                      disabledBackgroundColor: _brand.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(28)), // Match app buttons
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white)),
                          )
                        : const Text(
                            'Update PIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
