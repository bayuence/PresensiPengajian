import 'package:flutter/material.dart';
import '../../controllers/presensi_controller.dart';
import '../../models/presensi_jamaah.dart';
import 'input_presensi_page.dart';

class PresensiPage extends StatefulWidget {
  const PresensiPage({super.key});

  @override
  State<PresensiPage> createState() => _PresensiPageState();
}

class _PresensiPageState extends State<PresensiPage> {
  List<SesiPresensi> sesiList = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadSesi();
  }

  Future<void> loadSesi() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await PresensiController.fetchSesiList();
      setState(() {
        sesiList = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _mulaiPresensi() async {
    final nama = await showDialog<String>(
      context: context,
      builder: (context) => _DialogNamaSesi(),
    );

    if (nama != null && nama.isNotEmpty) {
      try {
        final sesiId = await PresensiController.mulaiSesi(namaPengajian: nama);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InputPresensiPage(sesiId: sesiId, namaSesi: nama),
            ),
          ).then((_) => loadSesi());
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Presensi"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: loadSesi,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: loadSesi, child: const Text("Coba Lagi")),
                  ],
                ),
              )
            : _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mulaiPresensi,
        icon: const Icon(Icons.add),
        label: const Text("Mulai Presensi"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildBody() {
    if (sesiList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Belum ada sesi presensi hari ini', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Tekan tombol "Mulai Presensi" untuk memulai', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: sesiList.length,
      itemBuilder: (context, index) {
        final sesi = sesiList[index];
        return _SesiCard(
          sesi: sesi,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => InputPresensiPage(sesiId: sesi.id, namaSesi: sesi.namaPengajian)),
            ).then((_) => loadSesi());
          },
          onAkhiri: sesi.isBerlangsung ? () => _akhiriSesi(sesi) : null,
        );
      },
    );
  }

  Future<void> _akhiriSesi(SesiPresensi sesi) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Akhiri Sesi?"),
        content: Text("Jamaah yang belum presensi di sesi '${sesi.namaPengajian}' akan otomatis ditandai 'Tidak Hadir'.\n\nYakin ingin mengakhiri sesi ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("Akhiri")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await PresensiController.akhiriSesi(sesiId: sesi.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesi berhasil diakhiri'), backgroundColor: Colors.green));
          loadSesi();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }
}

class _DialogNamaSesi extends StatefulWidget {
  @override
  State<_DialogNamaSesi> createState() => _DialogNamaSesiState();
}

class _DialogNamaSesiState extends State<_DialogNamaSesi> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Mulai Presensi Baru"),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(labelText: "Nama Pengajian", hintText: "Contoh: Kajian Fiqih", border: OutlineInputBorder()),
        autofocus: true,
        textCapitalization: TextCapitalization.words,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: const Text("Mulai"),
        ),
      ],
    );
  }
}

class _SesiCard extends StatelessWidget {
  final SesiPresensi sesi;
  final VoidCallback onTap;
  final VoidCallback? onAkhiri;

  const _SesiCard({required this.sesi, required this.onTap, this.onAkhiri});

  @override
  Widget build(BuildContext context) {
    final isBerlangsung = sesi.isBerlangsung;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(sesi.namaPengajian, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: isBerlangsung ? Colors.green : Colors.grey, borderRadius: BorderRadius.circular(20)),
                    child: Text(isBerlangsung ? "Berlangsung" : "Selesai", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text("Mulai: ${sesi.waktuMulai}", style: TextStyle(color: Colors.grey[600])),
                  if (sesi.waktuSelesai != null) ...[
                    const SizedBox(width: 16),
                    Text("Selesai: ${sesi.waktuSelesai}", style: TextStyle(color: Colors.grey[600])),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatChip(icon: Icons.check_circle, label: "Hadir", count: sesi.jumlahHadir, color: Colors.green),
                  const SizedBox(width: 8),
                  _StatChip(icon: Icons.info, label: "Izin", count: sesi.jumlahIzin, color: Colors.orange),
                  const SizedBox(width: 8),
                  _StatChip(icon: Icons.cancel, label: "Tidak Hadir", count: sesi.jumlahTidakHadir, color: Colors.red),
                  const Spacer(),
                  if (onAkhiri != null)
                    ElevatedButton.icon(
                      onPressed: onAkhiri,
                      icon: const Icon(Icons.stop_circle, size: 18),
                      label: const Text("Akhiri"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatChip({required this.icon, required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text("$count", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
