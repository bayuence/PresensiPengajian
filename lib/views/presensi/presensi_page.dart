import 'dart:async';
import 'package:flutter/material.dart';
import '../../controllers/presensi_controller.dart';
import '../../models/presensi_jamaah.dart';
import 'sesi/input_presensi.dart';
import 'rekap/rekap_table.dart';

class PresensiPage extends StatefulWidget {
  const PresensiPage({super.key});

  @override
  State<PresensiPage> createState() => _PresensiPageState();
}

class _PresensiPageState extends State<PresensiPage> with TickerProviderStateMixin {
  // Data
  List<SesiPresensi> sesiList = [];
  bool loading = true;
  String? error;
  
  // Tabs
  int _mainTab = 0; // 0 = Sesi, 1 = Rekap
  int _sesiFilter = 0; // 0 = Semua, 1 = Aktif, 2 = Selesai
  
  // Timer
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  
  // Rekap
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadSesi();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadSesi() async {
    setState(() { loading = true; error = null; });
    try {
      final tanggal = _mainTab == 1
          ? "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}"
          : null;
      final data = await PresensiController.fetchSesiList(tanggal: tanggal);
      setState(() { sesiList = data; loading = false; });
    } catch (e) {
      setState(() { error = e.toString(); loading = false; });
    }
  }

  List<SesiPresensi> get filteredSesi {
    if (_sesiFilter == 1) return sesiList.where((s) => s.isBerlangsung).toList();
    if (_sesiFilter == 2) return sesiList.where((s) => !s.isBerlangsung).toList();
    return sesiList;
  }

  int get totalHadir => sesiList.fold(0, (sum, s) => sum + s.jumlahHadir);
  int get totalIzin => sesiList.fold(0, (sum, s) => sum + s.jumlahIzin);
  int get totalTidakHadir => sesiList.fold(0, (sum, s) => sum + s.jumlahTidakHadir);
  int get sesiAktif => sesiList.where((s) => s.isBerlangsung).length;

  String _getFormattedDate([DateTime? date]) {
    final d = date ?? DateTime.now();
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${days[d.weekday % 7]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2E7D32)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      loadSesi();
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadSesi,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildMainTabs()),
              if (_mainTab == 0) ...[
                SliverToBoxAdapter(child: _buildStats()),
                SliverToBoxAdapter(child: _buildSesiFilters()),
              ] else ...[
                SliverToBoxAdapter(child: _buildDatePicker()),
              ],
              _buildContent(),
            ],
          ),
        ),
      ),
      floatingActionButton: _mainTab == 0 ? _buildFAB() : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.event_note, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Presensi Pengajian",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      _getFormattedDate(),
                      style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                    ),
                  ],
                ),
              ),
              // Live clock
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _MainTabButton(
              icon: Icons.list_alt,
              label: "Sesi Presensi",
              isSelected: _mainTab == 0,
              onTap: () {
                setState(() => _mainTab = 0);
                loadSesi();
              },
            ),
            const SizedBox(width: 8),
            _MainTabButton(
              icon: Icons.analytics_outlined,
              label: "Rekap",
              isSelected: _mainTab == 1,
              onTap: () {
                setState(() => _mainTab = 1);
                loadSesi();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF2E7D32).withOpacity(0.08), const Color(0xFF43A047).withOpacity(0.04)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.15)),
        ),
        child: Row(
          children: [
            _StatItem(icon: Icons.check_circle, value: totalHadir, label: "Hadir", color: const Color(0xFF2E7D32)),
            _StatDivider(),
            _StatItem(icon: Icons.info_outline, value: totalIzin, label: "Izin", color: Colors.orange),
            _StatDivider(),
            _StatItem(icon: Icons.cancel_outlined, value: totalTidakHadir, label: "Absen", color: Colors.red),
            _StatDivider(),
            _StatItem(icon: Icons.play_circle, value: sesiAktif, label: "Aktif", color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildSesiFilters() {
    final filters = [
      {'label': 'Semua', 'count': sesiList.length},
      {'label': 'Aktif', 'count': sesiList.where((s) => s.isBerlangsung).length},
      {'label': 'Selesai', 'count': sesiList.where((s) => !s.isBerlangsung).length},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: List.generate(filters.length, (index) {
          final isSelected = _sesiFilter == index;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: index > 0 ? 8 : 0),
              child: InkWell(
                onTap: () => setState(() => _sesiFilter = index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "${filters[index]['count']}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF2E7D32),
                        ),
                      ),
                      Text(
                        filters[index]['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: InkWell(
        onTap: _selectDate,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today, color: Color(0xFF2E7D32), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Pilih Tanggal", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    const SizedBox(height: 2),
                    Text(
                      _getFormattedDate(_selectedDate),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_drop_down, color: Color(0xFF2E7D32)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
      );
    }

    if (error != null) {
      return SliverFillRemaining(child: _buildError());
    }

    final list = _mainTab == 0 ? filteredSesi : sesiList;
    
    if (list.isEmpty) {
      return SliverFillRemaining(child: _buildEmpty());
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final sesi = list[index];
            return _SesiCard(
              sesi: sesi,
              isRekap: _mainTab == 1,
              onTap: () {
                if (_mainTab == 1) {
                  // Rekap mode - buka tabel
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RekapTable(
                        sesiId: sesi.id,
                        namaSesi: sesi.namaPengajian,
                        tanggal: _getFormattedDate(_selectedDate),
                      ),
                    ),
                  );
                } else {
                  // Sesi mode - hanya buka input presensi jika sesi masih aktif
                  if (sesi.isBerlangsung) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InputPresensiPage(sesiId: sesi.id, namaSesi: sesi.namaPengajian),
                      ),
                    ).then((_) => loadSesi());
                  } else {
                    // Sesi sudah selesai - tampilkan pesan
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Sesi ini sudah selesai dan tidak dapat diubah'),
                          ],
                        ),
                        backgroundColor: Colors.grey[600],
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              onAkhiri: sesi.isBerlangsung && _mainTab == 0 ? () => _akhiriSesi(sesi) : null,
              onHapus: _mainTab == 1 ? () => _hapusSesi(sesi) : null,
            );
          },
          childCount: list.length,
        ),
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
          Text(error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: loadSesi,
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _mainTab == 1 ? Icons.analytics_outlined : Icons.event_note,
              size: 56,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _mainTab == 1 ? "Tidak ada sesi di tanggal ini" : "Belum ada sesi presensi",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            _mainTab == 1 ? "Coba pilih tanggal lain" : 'Tekan tombol "Mulai Presensi"',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        heroTag: 'presensi_fab_mulai',
        onPressed: _mulaiPresensi,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text("Mulai Presensi", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }

  Future<void> _akhiriSesi(SesiPresensi sesi) async {
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
        content: Text(
          "Jamaah yang belum presensi di '${sesi.namaPengajian}' akan ditandai 'Tidak Hadir'.",
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Batal", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Akhiri"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await PresensiController.akhiriSesi(sesiId: sesi.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('Sesi berhasil diakhiri')],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          loadSesi();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _hapusSesi(SesiPresensi sesi) async {
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
              child: const Icon(Icons.delete_forever, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text("Hapus Sesi?"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Anda akan menghapus sesi '${sesi.namaPengajian}'.",
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Semua data presensi di sesi ini akan ikut terhapus!",
                      style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
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
            icon: const Icon(Icons.delete, size: 18),
            label: const Text("Hapus"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await PresensiController.hapusSesi(sesiId: sesi.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('Sesi berhasil dihapus')],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
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

// WIDGETS

class _MainTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MainTabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF43A047)])
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _StatItem({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text("$value", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: Colors.grey.shade200);
  }
}

class _SesiCard extends StatelessWidget {
  final SesiPresensi sesi;
  final bool isRekap;
  final VoidCallback onTap;
  final VoidCallback? onAkhiri;
  final VoidCallback? onHapus;

  const _SesiCard({required this.sesi, this.isRekap = false, required this.onTap, this.onAkhiri, this.onHapus});

  @override
  Widget build(BuildContext context) {
    final isBerlangsung = sesi.isBerlangsung;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isBerlangsung && !isRekap
            ? Border.all(color: const Color(0xFF2E7D32).withOpacity(0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Opacity(
        opacity: (!isRekap && !isBerlangsung) ? 0.7 : 1.0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isBerlangsung
                                ? [const Color(0xFF2E7D32), const Color(0xFF43A047)]
                                : [Colors.grey.shade400, Colors.grey.shade500],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isRekap ? Icons.table_chart : (isBerlangsung ? Icons.play_circle : Icons.check_circle),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sesi.namaPengajian,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 13, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  "${sesi.waktuMulai}${sesi.waktuSelesai != null ? ' - ${sesi.waktuSelesai}' : ''}",
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!isRekap)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isBerlangsung ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isBerlangsung)
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                ),
                              Text(
                                isBerlangsung ? "Aktif" : "Selesai",
                                style: TextStyle(
                                  color: isBerlangsung ? Colors.green : Colors.grey[600],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _MiniStat(icon: Icons.check_circle, count: sesi.jumlahHadir, color: const Color(0xFF2E7D32)),
                      const SizedBox(width: 12),
                      _MiniStat(icon: Icons.info_outline, count: sesi.jumlahIzin, color: Colors.orange),
                      const SizedBox(width: 12),
                      _MiniStat(icon: Icons.cancel_outlined, count: sesi.jumlahTidakHadir, color: Colors.red),
                      const Spacer(),
                      if (onAkhiri != null)
                        InkWell(
                          onTap: onAkhiri,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.stop_circle, size: 14, color: Colors.red),
                                SizedBox(width: 4),
                                Text("Akhiri", style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      if (onHapus != null)
                        InkWell(
                          onTap: onHapus,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete_outline, size: 14, color: Colors.red),
                                SizedBox(width: 4),
                                Text("Hapus", style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;

  const _MiniStat({required this.icon, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text("$count", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.play_circle, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 12),
          const Text("Mulai Presensi"),
        ],
      ),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: "Nama Pengajian",
          hintText: "Contoh: Kajian Fiqih",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: const Icon(Icons.mosque),
        ),
        autofocus: true,
        textCapitalization: TextCapitalization.words,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Batal", style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
          ),
          child: const Text("Mulai"),
        ),
      ],
    );
  }
}
