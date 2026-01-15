import 'package:flutter/material.dart';
import '../../controllers/presensi_controller.dart';
import '../../models/presensi_jamaah.dart';
import '../presensi/sesi/input_presensi.dart';

class InputPresensiCepat extends StatefulWidget {
  const InputPresensiCepat({super.key});

  @override
  State<InputPresensiCepat> createState() => _InputPresensiCepatState();
}

class _InputPresensiCepatState extends State<InputPresensiCepat> {
  final _namaController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;
  SesiPresensi? _sesiAktif;

  @override
  void initState() {
    super.initState();
    _cekSesiAktif();
  }

  Future<void> _cekSesiAktif() async {
    setState(() => _isLoading = true);
    
    try {
      final sesiAktif = await PresensiController.fetchSesiAktif();
      if (mounted) {
        setState(() {
          _sesiAktif = sesiAktif;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _mulaiSesi() async {
    final nama = _namaController.text.trim();
    if (nama.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final sesiId = await PresensiController.mulaiSesi(namaPengajian: nama);
      
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InputPresensiPage(sesiId: sesiId, namaSesi: nama),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _lanjutkanPresensi() {
    if (_sesiAktif == null) return;
    
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InputPresensiPage(
          sesiId: _sesiAktif!.id,
          namaSesi: _sesiAktif!.namaPengajian,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Mengecek sesi presensi..."),
          ],
        ),
      );
    }

    // Jika ada sesi aktif, tampilkan info sesi tersebut
    if (_sesiAktif != null) {
      return AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.play_circle, color: Colors.green),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text("Sesi Aktif")),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _sesiAktif!.namaPengajian,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "Mulai: ${_sesiAktif!.waktuMulai}",
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "Hadir: ${_sesiAktif!.jumlahHadir} jamaah",
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Sesi presensi sedang berlangsung. Lanjutkan untuk mendata kehadiran jamaah.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: _lanjutkanPresensi,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text("Lanjutkan Presensi"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    }

    // Tidak ada sesi aktif, tampilkan form untuk mulai sesi baru
    return AlertDialog(
      title: const Text("Mulai Presensi Baru"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _namaController,
            decoration: const InputDecoration(
              labelText: "Nama Pengajian",
              hintText: "Contoh: Kajian ba'da Maghrib",
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          const SizedBox(height: 12),
          const Text(
            "Setelah memulai, Anda akan diarahkan ke halaman presensi untuk mendata jamaah.",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Batal", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _mulaiSesi,
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Mulai"),
        ),
      ],
    );
  }
}
