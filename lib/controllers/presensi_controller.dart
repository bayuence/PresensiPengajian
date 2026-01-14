import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/presensi_jamaah.dart';
import '../config/api.dart';

class PresensiController {
  // ========== SESI FUNCTIONS ==========

  // GET - Ambil list sesi hari ini
  static Future<List<SesiPresensi>> fetchSesiList({String? tanggal}) async {
    final tgl = tanggal ?? DateTime.now().toString().substring(0, 10);
    final response = await http.get(
      Uri.parse("${Api.presensi}?action=sesi&tanggal=$tgl"),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] == true) {
        final List list = jsonData['data'];
        return list.map((e) => SesiPresensi.fromJson(e)).toList();
      }
    }
    throw Exception("Gagal mengambil data sesi");
  }

  // POST - Mulai sesi baru
  static Future<int> mulaiSesi({required String namaPengajian}) async {
    final now = DateTime.now();
    final response = await http.post(
      Uri.parse("${Api.presensi}?action=mulai"),
      body: {
        "nama_pengajian": namaPengajian,
        "tanggal": now.toString().substring(0, 10),
        "waktu_mulai":
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}",
      },
    );

    final jsonData = jsonDecode(response.body);
    if (jsonData['success'] == true) {
      return jsonData['id'];
    }
    throw Exception(jsonData['message'] ?? "Gagal memulai sesi");
  }

  // POST - Akhiri sesi
  static Future<void> akhiriSesi({required int sesiId}) async {
    final response = await http.post(
      Uri.parse("${Api.presensi}?action=akhiri"),
      body: {"sesi_id": sesiId.toString()},
    );

    final jsonData = jsonDecode(response.body);
    if (jsonData['success'] != true) {
      throw Exception(jsonData['message'] ?? "Gagal mengakhiri sesi");
    }
  }

  // ========== PRESENSI FUNCTIONS ==========

  // GET - Ambil detail presensi per sesi (list jamaah dengan status)
  static Future<List<PresensiJamaah>> fetchPresensiDetail({
    required int sesiId,
  }) async {
    final response = await http.get(
      Uri.parse("${Api.presensi}?action=detail&sesi_id=$sesiId"),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] == true) {
        final List list = jsonData['data'];
        return list.map((e) => PresensiJamaah.fromJson(e)).toList();
      }
    }
    throw Exception("Gagal mengambil detail presensi");
  }

  // POST - Submit presensi (Hadir/Izin)
  static Future<void> submitPresensi({
    required int sesiId,
    required int jamaahId,
    required String status,
  }) async {
    final now = DateTime.now();
    final response = await http.post(
      Uri.parse(Api.presensi),
      body: {
        "sesi_id": sesiId.toString(),
        "jamaah_id": jamaahId.toString(),
        "status": status,
        "tanggal": now.toString().substring(0, 10),
        "waktu":
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}",
      },
    );

    final jsonData = jsonDecode(response.body);
    if (jsonData['success'] != true) {
      throw Exception(jsonData['message'] ?? "Gagal menyimpan presensi");
    }
  }

  // ========== LEGACY (untuk kompatibilitas) ==========

  static Future<List<PresensiModel>> fetchPresensi() async {
    final response = await http.get(Uri.parse(Api.presensi));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List list = jsonData['data'];

      return list.map((e) => PresensiModel.fromJson(e)).toList();
    } else {
      throw Exception("Gagal mengambil data presensi");
    }
  }
}
