import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/account_user.dart';

class AuthController {
  static const String baseUrl = "http://10.10.10.47/presensi_pengajian";

  // Login
  static Future<AccountUser> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth.php?action=login"),
      body: {"username": username, "password": password},
    );

    final jsonData = jsonDecode(response.body);

    if (jsonData['success'] == true) {
      return AccountUser.fromJson(jsonData['data']);
    } else {
      throw Exception(jsonData['message'] ?? "Login gagal");
    }
  }

  // Cek user masih valid (opsional)
  static Future<AccountUser?> checkUser({required int userId}) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/auth.php?action=check&user_id=$userId"),
      );

      final jsonData = jsonDecode(response.body);

      if (jsonData['success'] == true) {
        return AccountUser.fromJson(jsonData['data']);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }
}
