import 'dart:convert';
import 'package:http/http.dart' as http;

class JamaahController {
  static Future<String> fetchJamaah() async {
    final url = Uri.parse(
      'http://localhost/presensi_pengajian/jamaah.php',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return response.body; // JSON masih String
    } else {
      throw Exception('Gagal mengambil data jamaah');
    }
  }
}
