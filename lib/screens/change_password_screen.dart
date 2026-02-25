import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reset_flow/services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  static const _brand = Color(0xFF5C35C2);
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
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _brand, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      counterStyle: const TextStyle(fontSize: 0, height: 0), // hide counter
      suffixIcon: IconButton(
        onPressed: toggle,
        icon: Icon(
          show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: Colors.grey.shade400,
          size: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Ambient blobs
          Positioned(
            top: -60,
            right: -60,
            child: _blob(200, const Color(0xFFEDE9FB)),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: _blob(160, const Color(0xFFF3F0FD)),
          ),
          SafeArea(
            child: Column(
              children: [
                // Custom app bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20, color: Color(0xFF1A1A2E)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEDE9FB),
                              boxShadow: [
                                BoxShadow(
                                  color: _brand.withOpacity(0.15),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.lock_outline_rounded,
                                color: _brand, size: 28),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Change PIN',
                            style: TextStyle(
                              color: Color(0xFF1A1A2E),
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Enter your current PIN, then set a new one.',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 36),
                          // Current PIN
                          TextFormField(
                            controller: _currentCtrl,
                            obscureText: !_showCurrent,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            style: const TextStyle(
                                color: Color(0xFF1A1A2E),
                                fontSize: 22,
                                letterSpacing: 10),
                            decoration: _inp(
                                'Current PIN',
                                _showCurrent,
                                () => setState(
                                    () => _showCurrent = !_showCurrent)),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (v.trim().length < 4) return 'PIN must be 4 digits';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          // New PIN
                          TextFormField(
                            controller: _newCtrl,
                            obscureText: !_showNew,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            style: const TextStyle(
                                color: Color(0xFF1A1A2E),
                                fontSize: 22,
                                letterSpacing: 10),
                            decoration: _inp(
                                'New PIN',
                                _showNew,
                                () => setState(() => _showNew = !_showNew)),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (v.trim().length < 4) return 'PIN must be 4 digits';
                              if (v.trim() == _currentCtrl.text.trim())
                                return 'New PIN must differ from current';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          // Confirm PIN
                          TextFormField(
                            controller: _confirmCtrl,
                            obscureText: !_showConfirm,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            style: const TextStyle(
                                color: Color(0xFF1A1A2E),
                                fontSize: 22,
                                letterSpacing: 10),
                            decoration: _inp(
                                'Confirm New PIN',
                                _showConfirm,
                                () => setState(
                                    () => _showConfirm = !_showConfirm)),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (v.trim() != _newCtrl.text.trim())
                                return 'PINs do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          // Error banner
                          if (_errorMsg != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.red.shade400, size: 18),
                                  const SizedBox(width: 8),
                                  Text(_errorMsg!,
                                      style: TextStyle(
                                          color: Colors.red.shade500,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                          // Success banner
                          if (_success)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      color: Colors.green.shade500, size: 18),
                                  const SizedBox(width: 8),
                                  Text('PIN updated successfully!',
                                      style: TextStyle(
                                          color: Colors.green.shade600,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                          const SizedBox(height: 28),
                          // Submit
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _loading || _success ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _brand,
                                disabledBackgroundColor:
                                    _brand.withOpacity(0.35),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                              Colors.white)),
                                    )
                                  : const Text(
                                      'Update PIN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}
