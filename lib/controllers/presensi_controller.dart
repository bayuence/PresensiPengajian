import 'dart:convert';
import 'dart:io';
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

  // GET - Ambil sesi yang sedang aktif (status = 'berlangsung')
  static Future<SesiPresensi?> fetchSesiAktif() async {
    final today = DateTime.now().toString().substring(0, 10);
    final response = await http.get(
      Uri.parse("${Api.presensi}?action=sesi&tanggal=$today"),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] == true) {
        final List list = jsonData['data'];
        // Cari sesi yang status-nya 'berlangsung'
        for (var item in list) {
          if (item['status'] == 'berlangsung') {
            return SesiPresensi.fromJson(item);
          }
        }
      }
    }
    // Tidak ada sesi aktif
    return null;
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

  // POST - Hapus sesi
  static Future<void> hapusSesi({required int sesiId}) async {
    final response = await http.post(
      Uri.parse("${Api.presensi}?action=hapus"),
      body: {"sesi_id": sesiId.toString()},
    );

    final jsonData = jsonDecode(response.body);
    if (jsonData['success'] != true) {
      throw Exception(jsonData['message'] ?? "Gagal menghapus sesi");
    }
  }

  //PRESENSI FUNCTIONS

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

  // POST - Submit presensi (Hadir/Izin + Foto Bukti)
  static Future<void> submitPresensi({
    required int sesiId,
    required int jamaahId,
    required String status,
    File? fotoBukti,
  }) async {
    final now = DateTime.now();
    final uri = Uri.parse(Api.presensi);
    final fields = {
      "sesi_id": sesiId.toString(),
      "jamaah_id": jamaahId.toString(),
      "status": status,
      "tanggal": now.toString().substring(0, 10),
      "waktu":
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}",
    };

    if (fotoBukti != null) {
      // Use MultipartRequest for file upload
      var request = http.MultipartRequest('POST', uri);
      request.fields.addAll(fields);
      request.files.add(
        await http.MultipartFile.fromPath('foto_bukti', fotoBukti.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] != true) {
        throw Exception(
          jsonData['message'] ?? "Gagal menyimpan presensi dengan foto",
        );
      }
    } else {
      // Standard POST if no file
      final response = await http.post(uri, body: fields);
      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] != true) {
        throw Exception(jsonData['message'] ?? "Gagal menyimpan presensi");
      }
    }
  }

  //LEGACY (untuk kompatibilitas)

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

  // GET - Ambil rekap presensi (semua data untuk periode tertentu)
  static Future<List<Map<String, dynamic>>> fetchRekapPresensi({
    String? startDate,
    String? endDate,
  }) async {
    // Ambil semua sesi dalam periode
    final allSesi = <SesiPresensi>[];

    // Jika tidak ada filter, ambil 30 hari terakhir
    final end = endDate != null ? DateTime.parse(endDate) : DateTime.now();
    final start = startDate != null
        ? DateTime.parse(startDate)
        : end.subtract(const Duration(days: 30));

    // Ambil data per hari
    for (
      var date = start;
      !date.isAfter(end);
      date = date.add(const Duration(days: 1))
    ) {
      try {
        final tanggal =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        final sesiList = await fetchSesiList(tanggal: tanggal);
        allSesi.addAll(sesiList);
      } catch (e) {
        // Ignore errors for individual days
      }
    }

    // Hitung statistik per jamaah
    final jamaahStats = <int, Map<String, dynamic>>{};

    for (var sesi in allSesi) {
      if (sesi.status != 'selesai')
        continue; // Hanya hitung sesi yang sudah selesai

      try {
        final detail = await fetchPresensiDetail(sesiId: sesi.id);
        for (var item in detail) {
          if (!jamaahStats.containsKey(item.jamaahId)) {
            jamaahStats[item.jamaahId] = {
              'jamaahId': item.jamaahId,
              'nama': item.nama,
              'foto': item.foto,
              'totalSesi': 0,
              'hadir': 0,
              'izin': 0,
              'tidakHadir': 0,
            };
          }

          jamaahStats[item.jamaahId]!['totalSesi']++;
          if (item.status == 'Hadir') {
            jamaahStats[item.jamaahId]!['hadir']++;
          } else if (item.status == 'Izin') {
            jamaahStats[item.jamaahId]!['izin']++;
          } else {
            jamaahStats[item.jamaahId]!['tidakHadir']++;
          }
        }
      } catch (e) {
        // Ignore errors
      }
    }

    // Convert to list and sort by hadir descending
    final result = jamaahStats.values.toList();
    result.sort((a, b) => (b['hadir'] as int).compareTo(a['hadir'] as int));

    return result;
  }
}
