import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/presensi_model.dart';

class PresensiController {
  static const String baseUrl = "http://localhost/presensi_pengajian";

  // AMBIL DATA PRESENSI

  static Future<List<PresensiModel>> fetchPresensi() async {
    final response = await http.get(Uri.parse("$baseUrl/presensi_list.php"));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List list = jsonData['data'];

      return list.map((e) => PresensiModel.fromJson(e)).toList();
    } else {
      throw Exception("Gagal mengambil data presensi");
    }
  }

  // SIMPAN / UPDATE PRESENSI

  static Future<void> submitPresensi({
    required int jamaahId,
    required String status,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/presensi_input.php"),
      body: {"jamaah_id": jamaahId.toString(), "status": status},
    );

    final jsonData = jsonDecode(response.body);

    if (jsonData['result'] != 'success') {
      throw Exception("Gagal menyimpan presensi");
    }
  }
}
