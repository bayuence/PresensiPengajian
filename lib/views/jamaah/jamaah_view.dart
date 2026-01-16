import 'package:flutter/material.dart';
import '../../controllers/jamaah_controller.dart';
import '../../models/jamaah.dart';
import '../../config/api.dart';
import 'tambah_jamaah_page.dart';

class JamaahView extends StatefulWidget {
  const JamaahView({super.key});

  @override
  State<JamaahView> createState() => _JamaahViewState();
}

class _JamaahViewState extends State<JamaahView> {
  List<Jamaah> jamaahList = [];
  List<Jamaah> filteredList = [];
  bool loading = true;
  String? error;
  final JamaahController _controller = JamaahController();
  final TextEditingController _searchController = TextEditingController();

  static const Color _primaryColor = Color(0xFF2E7D32);
  static const Color _primaryLightColor = Color(0xFF43A047);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await JamaahController.fetchJamaahModel();
      if (mounted) {
        setState(() {
          jamaahList = data;
          filteredList = data;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }
    }
  }

  void _filterJamaah(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredList = jamaahList;
      } else {
        filteredList = jamaahList
            .where((j) => j.nama.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _navigateToForm([Jamaah? jamaah]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TambahJamaahPage(jamaah: jamaah)),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _confirmDelete(Jamaah jamaah) async {
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
            const Text('Hapus Jamaah?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda akan menghapus jamaah "${jamaah.nama}".',
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
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Data presensi jamaah ini juga akan terhapus!',
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
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Hapus'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _controller.deleteJamaah(jamaah.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(success ? Icons.check_circle : Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text(success ? 'Jamaah berhasil dihapus' : 'Gagal menghapus jamaah'),
              ],
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        if (success) {
          _loadData();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: _primaryColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildStats()),
              _buildContent(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryColor, _primaryLightColor],
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
                child: const Icon(Icons.people_alt, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Data Jamaah",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      "Kelola daftar jamaah pengajian",
                      style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.mosque, color: Colors.white, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _filterJamaah,
          decoration: InputDecoration(
            hintText: 'Cari jamaah...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.search, color: _primaryColor),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _filterJamaah('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
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
            colors: [_primaryColor.withOpacity(0.08), _primaryLightColor.withOpacity(0.04)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _primaryColor.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            _StatItem(
              icon: Icons.people,
              value: jamaahList.length,
              label: "Total Jamaah",
              color: _primaryColor,
            ),
            Container(width: 1, height: 40, color: Colors.grey.shade300),
            _StatItem(
              icon: Icons.search,
              value: filteredList.length,
              label: "Ditampilkan",
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: _primaryColor)),
      );
    }

    if (error != null) {
      return SliverFillRemaining(child: _buildError());
    }

    if (filteredList.isEmpty) {
      return SliverFillRemaining(child: _buildEmpty());
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final jamaah = filteredList[index];
            return _JamaahCard(
              jamaah: jamaah,
              index: index + 1,
              onEdit: () => _navigateToForm(jamaah),
              onDelete: () => _confirmDelete(jamaah),
            );
          },
          childCount: filteredList.length,
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
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text("Coba Lagi"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final isSearching = _searchController.text.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearching ? Icons.search_off : Icons.people_outline,
              size: 56,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isSearching ? 'Jamaah tidak ditemukan' : 'Belum ada data jamaah',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching ? 'Coba kata kunci lain' : 'Tekan tombol + untuk menambah jamaah',
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
            color: _primaryColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        heroTag: 'jamaah_fab_add',
        onPressed: () => _navigateToForm(),
        icon: const Icon(Icons.person_add),
        label: const Text("Tambah Jamaah", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}

//  WIDGETS 

class _StatItem extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _StatItem({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$value", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
}

class _JamaahCard extends StatelessWidget {
  final Jamaah jamaah;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _JamaahCard({
    required this.jamaah,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Number badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      "$index",
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
                    backgroundImage: jamaah.foto != null && jamaah.foto!.isNotEmpty
                        ? NetworkImage(Api.uploadUrl(jamaah.foto!))
                        : null,
                    child: jamaah.foto == null || jamaah.foto!.isEmpty
                        ? Text(
                            jamaah.nama.isNotEmpty ? jamaah.nama[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                // Name
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ID: ${jamaah.id}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(
                      icon: Icons.edit_outlined,
                      color: const Color(0xFF2E7D32),
                      bgColor: const Color(0xFFE8F5E9),
                      onTap: onEdit,
                      tooltip: "Edit",
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.delete_outline,
                      color: Colors.red,
                      bgColor: Colors.red.shade50,
                      onTap: onDelete,
                      tooltip: "Hapus",
                    ),
                  ],
                ),
              ],
            ),
          ),
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
