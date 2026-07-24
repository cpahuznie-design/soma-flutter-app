import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _keyIsLoggedIn = 'soma_logged_in';
  static const _keyUserName = 'soma_user_name';
  static const _keyUserEmail = 'soma_user_email';
  static const _keyUserPlan = 'soma_user_plan';
  static const _keyUserId = 'soma_user_id';

  static Future<void> login(String name, String email, {String plan = 'Free'}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserPlan, plan);
    await prefs.setString(_keyUserId, DateTime.now().millisecondsSinceEpoch.toString());
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserPlan);
    await prefs.remove(_keyUserId);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  static Future<String> getUserPlan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserPlan) ?? 'Free';
  }

  static Future<void> setUserPlan(String plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserPlan, plan);
  }
}