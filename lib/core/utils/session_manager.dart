import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _keyUser = "userData";

   Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyUser);
    if (data == null) return null;
    return jsonDecode(data);
  }

  Future<void> saveUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(userData));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
  }
}
