import 'dart:convert';
import 'package:http/http.dart' as http;

class JamaahService {
  static Future<Map<String, String>> fetchJamaahMap() async {
    final url = Uri.parse(
      "http://localhost/presensi_pengajian/jamaah_list.php",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List list = jsonData['data'];

      // hasil: { "1": "Bayu", "2": "Ence" }
      return {
        for (var j in list) j['id'].toString(): j['nama'].toString()
      };
    } else {
      throw Exception("Gagal ambil data jamaah");
    }
  }
}
