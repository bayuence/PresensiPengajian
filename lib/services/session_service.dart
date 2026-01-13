import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account_user.dart';

class SessionService {
  static const String _keyUser = 'user_data';
  static const String _keyLoggedIn = 'is_logged_in';

  // Simpan session setelah login
  static Future<void> saveSession(AccountUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    await prefs.setBool(_keyLoggedIn, true);
  }

  // Ambil data user dari session
  static Future<AccountUser?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_keyUser);

    if (userData != null) {
      return AccountUser.fromJson(jsonDecode(userData));
    }
    return null;
  }

  // Cek apakah sudah login
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  // Logout - hapus session
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.setBool(_keyLoggedIn, false);
  }

  // Clear semua data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
