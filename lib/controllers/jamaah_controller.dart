import 'dart:convert';
import 'dart:io';
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

  /// Tambah jamaah baru dengan foto (opsional)
  Future<bool> addJamaah({required String nama, File? foto}) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_baseUrl));

      request.fields['nama'] = nama;

      if (foto != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', foto.path));
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonData = jsonDecode(responseData);

      return jsonData['success'] == true;
    } catch (e) {
      print('Error addJamaah: $e');
      return false;
    }
  }

  /// Update jamaah (termasuk foto)
  Future<bool> updateJamaah({
    required int id,
    required String nama,
    File? foto,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_baseUrl));

      request.fields['id'] = id.toString();
      request.fields['nama'] = nama;
      request.fields['_method'] = 'PUT'; // Simulasi PUT method

      if (foto != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', foto.path));
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonData = jsonDecode(responseData);

      return jsonData['success'] == true;
    } catch (e) {
      print('Error updateJamaah: $e');
      return false;
    }
  }

  /// Hapus jamaah
  Future<bool> deleteJamaah(int id) async {
    try {
      final response = await http.delete(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        return jsonData['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error deleteJamaah: $e');
      return false;
    }
  }
}
