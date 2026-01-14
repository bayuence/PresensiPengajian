import 'package:flutter/material.dart';
import '../../controllers/presensi_controller.dart';
import '../presensi/input_presensi_page.dart';

class InputPresensiCepat extends StatefulWidget {
  const InputPresensiCepat({super.key});

  @override
  State<InputPresensiCepat> createState() => _InputPresensiCepatState();
}

class _InputPresensiCepatState extends State<InputPresensiCepat> {
  final _namaController = TextEditingController();
  bool _isLoading = false;

  Future<void> _mulaiSesi() async {
    final nama = _namaController.text.trim();
    if (nama.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final sesiId = await PresensiController.mulaiSesi(namaPengajian: nama);
      
      if (mounted) {
        Navigator.pop(context); // Tutup dialog
        // Langsung navigasi ke halaman input presensi full agar leluasa
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          onPressed: _isLoading ? null : _mulaiSesi,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Mulai"),
        ),
      ],
    );
  }
}
