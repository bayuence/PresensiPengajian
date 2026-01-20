import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/jamaah.dart';
import '../config/api.dart';

class JamaahController {
  /// Ambil data JSON mentah dari API
  static Future<String> fetchJamaahRaw() async {
    final response = await http.get(Uri.parse(Api.jamaah));

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

  /// Tambah jamaah baru dengan foto (opsional) - Support Web & Mobile
  Future<bool> addJamaah({
    required String nama, 
    Uint8List? fotoBytes,
    String? fotoName,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(Api.jamaah));

      request.fields['nama'] = nama;

      if (fotoBytes != null && fotoName != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'foto',
          fotoBytes,
          filename: fotoName,
        ));
        print('Uploading foto: $fotoName');
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      print('Server response: $responseData');
      var jsonData = jsonDecode(responseData);

      return jsonData['success'] == true;
    } catch (e) {
      print('Error addJamaah: $e');
      return false;
    }
  }

  /// Update jamaah (termasuk foto) - Support Web & Mobile
  Future<bool> updateJamaah({
    required int id,
    required String nama,
    Uint8List? fotoBytes,
    String? fotoName,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(Api.jamaah));

      request.fields['id'] = id.toString();
      request.fields['nama'] = nama;
      request.fields['_method'] = 'PUT'; // Simulasi PUT method

      if (fotoBytes != null && fotoName != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'foto',
          fotoBytes,
          filename: fotoName,
        ));
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
        Uri.parse(Api.jamaah),
        headers: Api.jsonHeaders,
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
