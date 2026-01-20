import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../controllers/presensi_controller.dart';
import '../../../models/presensi_jamaah.dart';
import '../../../config/api.dart';

class InputPresensiPage extends StatefulWidget {
  final int sesiId;
  final String namaSesi;

  const InputPresensiPage({
    super.key,
    required this.sesiId,
    required this.namaSesi,
  });

  @override
  State<InputPresensiPage> createState() => _InputPresensiPageState();
}

class _InputPresensiPageState extends State<InputPresensiPage>
    with SingleTickerProviderStateMixin {
  List<PresensiJamaah> jamaahList = [];
  bool loading = true;
  bool sesiAktif = true;
  String? error;

  // Timer untuk jam realtime
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  DateTime? _startTime;

  // Tab controller
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _startTime = DateTime.now();
    loadData();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  String get _elapsedTime {
    if (_startTime == null) return "00:00:00";
    final diff = _currentTime.difference(_startTime!);
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  Future<void> loadData() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await PresensiController.fetchPresensiDetail(
        sesiId: widget.sesiId,
      );
      setState(() {
        jamaahList = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _submitPresensi(
    int jamaahId,
    String status, {
    File? foto,
  }) async {
    try {
      await PresensiController.submitPresensi(
        sesiId: widget.sesiId,
        jamaahId: jamaahId,
        status: status,
        fotoBukti: foto,
      );
      loadData();
      if (mounted) {
        String message = 'Presensi berhasil diperbarui';
        Color color = Colors.blue;
        IconData icon = Icons.check_circle;

        if (status == 'Hadir') {
          message = 'Ditandai Hadir';
          color = const Color(0xFF2E7D32);
        } else if (status == 'Izin') {
          message = 'Ditandai Izin';
          color = Colors.orange;
          icon = Icons.info_outline;
        } else if (status == 'Belum') {
          message = 'Presensi dibatalkan (Reset)';
          color = Colors.grey;
          icon = Icons.refresh;
        } else if (status == 'Tidak Hadir') {
          message = 'Ditandai Tidak Hadir';
          color = Colors.red;
          icon = Icons.cancel;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(message),
              ],
            ),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _ambilFotoDanHadir(int jamaahId) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mengupload foto...'),
              duration: Duration(seconds: 1),
            ),
          );
        }
        await _submitPresensi(jamaahId, 'Hadir', foto: File(photo.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuka kamera: $e')));
      }
    }
  }

  void _showEditOptions(PresensiJamaah jamaah) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Ubah Status: ${jamaah.nama}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2E7D32),
                ),
                title: const Text("Hadir (Foto)"),
                subtitle: const Text("Ambil foto bukti kehadiran"),
                onTap: () {
                  Navigator.pop(context);
                  _ambilFotoDanHadir(jamaah.jamaahId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info, color: Colors.orange),
                title: const Text("Izin"),
                onTap: () {
                  Navigator.pop(context);
                  _submitPresensi(jamaah.jamaahId, 'Izin');
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text("Tidak Hadir (Absen)"),
                onTap: () {
                  Navigator.pop(context);
                  _submitPresensi(jamaah.jamaahId, 'Tidak Hadir');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.restart_alt, color: Colors.grey),
                title: const Text("Reset ke Belum"),
                onTap: () {
                  Navigator.pop(context);
                  _submitPresensi(jamaah.jamaahId, 'Belum');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _akhiriSesi() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.stop_circle, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text("Akhiri Sesi?"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Jamaah yang belum presensi akan otomatis ditandai 'Tidak Hadir'.",
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${jamaahList.where((j) => j.status == 'Belum').length} jamaah belum dipresensi",
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Batal", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.stop, size: 18),
            label: const Text("Akhiri Sesi"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await PresensiController.akhiriSesi(sesiId: widget.sesiId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Sesi berhasil diakhiri'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          setState(() {
            sesiAktif = false;
          });
          loadData();
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

  // Computed properties
  int get hadir => jamaahList.where((j) => j.status == 'Hadir').length;
  int get izin => jamaahList.where((j) => j.status == 'Izin').length;
  int get belum => jamaahList.where((j) => j.status == 'Belum').length;
  int get tidakHadir =>
      jamaahList.where((j) => j.status == 'Tidak Hadir').length;

  List<PresensiJamaah> get filteredList {
    switch (_tabController.index) {
      case 1:
        return jamaahList.where((j) => j.status == 'Hadir').toList();
      case 2:
        return jamaahList.where((j) => j.status == 'Izin').toList();
      case 3:
        return jamaahList
            .where((j) => j.status == 'Belum' || j.status == 'Tidak Hadir')
            .toList();
      default:
        return jamaahList;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildCompactHeader(),
            _buildStatCards(),
            _buildTabBar(),
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                      ),
                    )
                  : error != null
                  ? _buildError()
                  : _buildJamaahList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 1, // Presensi tab
          onTap: (index) {
            // Kembali ke MainNavigation dengan tab yang dipilih
            Navigator.pop(context);
            // Note: Untuk navigasi yang lebih baik, bisa menggunakan state management
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2E7D32),
          unselectedItemColor: Colors.grey[500],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fact_check_outlined),
              activeIcon: Icon(Icons.fact_check),
              label: 'Presensi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Jamaah',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
            ),
          ),
          const SizedBox(width: 12),
          // Title and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.namaSesi,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: sesiAktif ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sesiAktif ? "Berlangsung" : "Selesai",
                      style: TextStyle(
                        fontSize: 12,
                        color: sesiAktif ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Timer
          if (sesiAktif)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _elapsedTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          // Akhiri button
          if (sesiAktif) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: _akhiriSesi,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stop_circle, color: Colors.red, size: 16),
                    SizedBox(width: 4),
                    Text(
                      "Akhiri",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.check_circle,
            label: "Hadir",
            count: hadir,
            color: const Color(0xFF2E7D32),
            bgColor: const Color(0xFFE8F5E9),
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.info_outline,
            label: "Izin",
            count: izin,
            color: Colors.orange,
            bgColor: Colors.orange.shade50,
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.cancel_outlined,
            label: "Absen",
            count: tidakHadir,
            color: Colors.red,
            bgColor: Colors.red.shade50,
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.hourglass_empty,
            label: "Belum",
            count: belum,
            color: Colors.blueGrey,
            bgColor: Colors.blueGrey.shade50,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (_) => setState(() {}),
        indicator: BoxDecoration(
          color: const Color(0xFF2E7D32),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        tabs: [
          Tab(text: "Semua (${jamaahList.length})"),
          Tab(text: "Hadir ($hadir)"),
          Tab(text: "Izin ($izin)"),
          Tab(text: "Belum (${belum + tidakHadir})"),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, size: 48, color: Colors.red),
          ),
          const SizedBox(height: 16),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: loadData,
            icon: const Icon(Icons.refresh),
            label: const Text("Coba Lagi"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJamaahList() {
    final list = filteredList;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _tabController.index == 0 ? 'Belum ada jamaah' : 'Tidak ada data',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadData,
      color: const Color(0xFF2E7D32),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final jamaah = list[index];
          return _JamaahCard(
            jamaah: jamaah,
            sesiAktif: sesiAktif,
            onHadir: () => _ambilFotoDanHadir(jamaah.jamaahId),
            onIzin: () => _submitPresensi(jamaah.jamaahId, 'Izin'),
            onEdit: () => _showEditOptions(jamaah),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              "$count",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _JamaahCard extends StatelessWidget {
  final PresensiJamaah jamaah;
  final bool sesiAktif;
  final VoidCallback onHadir;
  final VoidCallback onIzin;
  final VoidCallback onEdit;

  const _JamaahCard({
    required this.jamaah,
    required this.sesiAktif,
    required this.onHadir,
    required this.onIzin,
    required this.onEdit,
  });

  Color get _statusColor {
    switch (jamaah.status) {
      case 'Hadir':
        return const Color(0xFF2E7D32);
      case 'Izin':
        return Colors.orange;
      case 'Tidak Hadir':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  IconData get _statusIcon {
    switch (jamaah.status) {
      case 'Hadir':
        return Icons.check_circle;
      case 'Izin':
        return Icons.info;
      case 'Tidak Hadir':
        return Icons.cancel;
      default:
        return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isBelum = jamaah.status == 'Belum';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isBelum
            ? Border.all(
                color: const Color(0xFF2E7D32).withOpacity(0.3),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _statusColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: _statusColor.withOpacity(0.1),
                backgroundImage: jamaah.foto != null && jamaah.foto!.isNotEmpty
                    ? NetworkImage(Api.uploadUrl(jamaah.foto!))
                    : null,
                child: jamaah.foto == null || jamaah.foto!.isEmpty
                    ? Text(
                        jamaah.nama.isNotEmpty
                            ? jamaah.nama[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _statusColor,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            // Name and status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jamaah.nama,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon, size: 12, color: _statusColor),
                        const SizedBox(width: 4),
                        Text(
                          jamaah.status,
                          style: TextStyle(
                            fontSize: 11,
                            color: _statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons
            if (sesiAktif) ...[
              if (isBelum) ...[
                _ActionButton(
                  icon: Icons.check_circle,
                  color: const Color(0xFF2E7D32),
                  bgColor: const Color(0xFFE8F5E9),
                  onTap: onHadir,
                  tooltip: "Hadir",
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.info_outline,
                  color: Colors.orange,
                  bgColor: Colors.orange.shade50,
                  onTap: onIzin,
                  tooltip: "Izin",
                ),
              ] else ...[
                _ActionButton(
                  icon: Icons.edit_outlined,
                  color: Colors.blueAccent,
                  bgColor: Colors.blue.shade50,
                  onTap: onEdit,
                  tooltip: "Ubah Status",
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}
