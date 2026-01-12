import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/presensi_model.dart';

class PresensiController {
  static Future<List<PresensiModel>> fetchPresensi() async {
    final url = Uri.parse(
      "http://localhost/presensi_pengajian/presensi_list.php",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List list = jsonData['data'];

      return list.map((e) => PresensiModel.fromJson(e)).toList();
    } else {
      throw Exception("Gagal mengambil data presensi");
    }
  }
}
