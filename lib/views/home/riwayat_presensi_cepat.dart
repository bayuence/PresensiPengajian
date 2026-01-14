import 'package:flutter/material.dart';
import '../../controllers/presensi_controller.dart';
import '../../models/presensi_jamaah.dart';
import '../presensi/input_presensi_page.dart';

class RiwayatPresensiCepat extends StatefulWidget {
  const RiwayatPresensiCepat({super.key});

  @override
  State<RiwayatPresensiCepat> createState() => _RiwayatPresensiCepatState();
}

class _RiwayatPresensiCepatState extends State<RiwayatPresensiCepat> {
  late Future<List<SesiPresensi>> _futureSesi;

  @override
  void initState() {
    super.initState();
    _futureSesi = PresensiController.fetchSesiList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Riwayat Terkini"),
      contentPadding: const EdgeInsets.fromLTRB(0, 20, 0, 24),
      content: SizedBox(
        width: double.maxFinite,
        height: 300, // Batasi tinggi agar tidak memenuhi layar
        child: FutureBuilder<List<SesiPresensi>>(
          future: _futureSesi,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Belum ada riwayat."));
            }

            final list = snapshot.data!.take(5).toList(); // Ambil 5 terakhir

            return ListView.separated(
              itemCount: list.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final sesi = list[index];
                return ListTile(
                  title: Text(
                    sesi.namaPengajian,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    "${sesi.waktuMulai} • ${sesi.jumlahHadir} Hadir",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: sesi.isBerlangsung ? Colors.green[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sesi.isBerlangsung ? Colors.green : Colors.grey,
                        width: 1,
                      )
                    ),
                    child: Text(
                      sesi.isBerlangsung ? "Aktif" : "Selesai",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: sesi.isBerlangsung ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InputPresensiPage(
                          sesiId: sesi.id,
                          namaSesi: sesi.namaPengajian,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Tutup"),
        ),
      ],
    );
  }
}
