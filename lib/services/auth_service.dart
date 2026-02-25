import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _key = 'rf_pin';
  static const _defaultPin = '1234';

  static Future<String> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? _defaultPin;
  }

  static Future<bool> verifyPin(String input) async {
    final pin = await getPin();
    return input == pin;
  }

  static Future<void> setPin(String newPin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, newPin);
  }
}
