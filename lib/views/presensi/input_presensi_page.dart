import 'package:flutter/material.dart';
import '../../controllers/presensi_controller.dart';
import '../../models/presensi_jamaah.dart';
import '../../config/api.dart';

class InputPresensiPage extends StatefulWidget {
  final int sesiId;
  final String namaSesi;

  const InputPresensiPage({super.key, required this.sesiId, required this.namaSesi});

  @override
  State<InputPresensiPage> createState() => _InputPresensiPageState();
}

class _InputPresensiPageState extends State<InputPresensiPage> {
  List<PresensiJamaah> jamaahList = [];
  bool loading = true;
  bool sesiAktif = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() { loading = true; error = null; });
    try {
      final data = await PresensiController.fetchPresensiDetail(sesiId: widget.sesiId);
      setState(() { jamaahList = data; loading = false; });
    } catch (e) {
      setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _submitPresensi(int jamaahId, String status) async {
    try {
      await PresensiController.submitPresensi(sesiId: widget.sesiId, jamaahId: jamaahId, status: status);
      loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Presensi $status berhasil'), backgroundColor: status == 'Hadir' ? Colors.green : Colors.orange, duration: const Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _akhiriSesi() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Akhiri Sesi?"),
        content: const Text("Jamaah yang belum presensi akan otomatis ditandai 'Tidak Hadir'.\n\nYakin ingin mengakhiri sesi ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("Akhiri")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await PresensiController.akhiriSesi(sesiId: widget.sesiId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesi berhasil diakhiri'), backgroundColor: Colors.green));
          setState(() { sesiAktif = false; });
          loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.namaSesi),
        centerTitle: true,
        actions: [
          if (sesiAktif)
            TextButton.icon(
              onPressed: _akhiriSesi,
              icon: const Icon(Icons.stop_circle, color: Colors.white),
              label: const Text("Akhiri", style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: loading
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
                  ElevatedButton(onPressed: loadData, child: const Text("Coba Lagi")),
                ],
              ),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (jamaahList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Belum ada data jamaah', style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Tambahkan jamaah terlebih dahulu', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }

    final hadir = jamaahList.where((j) => j.status == 'Hadir').length;
    final izin = jamaahList.where((j) => j.status == 'Izin').length;
    final belum = jamaahList.where((j) => j.status == 'Belum').length;
    final tidakHadir = jamaahList.where((j) => j.status == 'Tidak Hadir').length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: "Hadir", count: hadir, color: Colors.green),
              _StatItem(label: "Izin", count: izin, color: Colors.orange),
              _StatItem(label: "Tidak Hadir", count: tidakHadir, color: Colors.red),
              _StatItem(label: "Belum", count: belum, color: Colors.grey),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: loadData,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: jamaahList.length,
              itemBuilder: (context, index) {
                final jamaah = jamaahList[index];
                return _JamaahCard(
                  jamaah: jamaah,
                  sesiAktif: sesiAktif,
                  onHadir: () => _submitPresensi(jamaah.jamaahId, 'Hadir'),
                  onIzin: () => _submitPresensi(jamaah.jamaahId, 'Izin'),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatItem({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("$count", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

class _JamaahCard extends StatelessWidget {
  final PresensiJamaah jamaah;
  final bool sesiAktif;
  final VoidCallback onHadir;
  final VoidCallback onIzin;

  const _JamaahCard({required this.jamaah, required this.sesiAktif, required this.onHadir, required this.onIzin});

  Color get _statusColor {
    switch (jamaah.status) {
      case 'Hadir': return Colors.green;
      case 'Izin': return Colors.orange;
      case 'Tidak Hadir': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (jamaah.status) {
      case 'Hadir': return Icons.check_circle;
      case 'Izin': return Icons.info;
      case 'Tidak Hadir': return Icons.cancel;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[300],
              backgroundImage: jamaah.foto != null && jamaah.foto!.isNotEmpty
                  ? NetworkImage(Api.uploadUrl(jamaah.foto!))
                  : null,
              child: jamaah.foto == null || jamaah.foto!.isEmpty
                  ? const Icon(Icons.person, size: 30, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(jamaah.nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(_statusIcon, size: 16, color: _statusColor),
                      const SizedBox(width: 4),
                      Text(jamaah.status, style: TextStyle(color: _statusColor, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            if (sesiAktif && jamaah.status == 'Belum') ...[
              IconButton(onPressed: onHadir, icon: const Icon(Icons.check_circle, size: 36), color: Colors.green, tooltip: "Hadir"),
              IconButton(onPressed: onIzin, icon: const Icon(Icons.info, size: 36), color: Colors.orange, tooltip: "Izin"),
            ],
          ],
        ),
      ),
    );
  }
}
