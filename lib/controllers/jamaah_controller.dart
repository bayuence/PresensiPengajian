import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/jamaah.dart';

class JamaahController {
  static const String _baseUrl =
      'http://localhost/presensi_pengajian/jamaah.php';

  /// Ambil data JSON mentah dari API
  static Future<String> fetchJamaahRaw() async {
    final response = await http.get(Uri.parse(_baseUrl));

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Gagal mengambil data jamaah');
    }
  }

  /// Ambil data jamaah dalam bentuk List [Jamaah]
  static Future<List<Jamaah>> fetchJamaahModel() async {
    final String rawData = await fetchJamaahRaw();
    final Map<String, dynamic> jsonData = jsonDecode(rawData);

    List<Jamaah> jamaahList = [];

    if (jsonData['success'] == true) {
      for (var item in jsonData['data']) {
        jamaahList.add(Jamaah.fromJson(item));
      }
    }

    return jamaahList;
  }
}
