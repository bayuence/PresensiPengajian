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
  late Future<List<Jamaah>> futureJamaah;
  final JamaahController _controller = JamaahController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      futureJamaah = JamaahController.fetchJamaahModel();
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
        title: const Text('Konfirmasi'),
        content: Text('Hapus jamaah ${jamaah.nama}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _controller.deleteJamaah(jamaah.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Jamaah berhasil dihapus' : 'Gagal menghapus jamaah'),
            backgroundColor: success ? Colors.green : Colors.red,
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Data Jamaah'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'jamaah_fab_add',
        onPressed: () => _navigateToForm(),
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: FutureBuilder<List<Jamaah>>(
        future: futureJamaah,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final jamaahList = snapshot.data!;

          if (jamaahList.isEmpty) {
            return const Center(
              child: Text('Belum ada data jamaah', style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }

          return ListView.builder(
            itemCount: jamaahList.length,
            itemBuilder: (context, index) {
              final jamaah = jamaahList[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    backgroundImage: (jamaah.foto != null && jamaah.foto!.isNotEmpty)
                        ? NetworkImage(Api.uploadUrl(jamaah.foto!))
                        : null,
                    child: (jamaah.foto == null || jamaah.foto!.isEmpty)
                        ? const Icon(Icons.person, color: Colors.blue)
                        : null,
                  ),
                  title: Text(jamaah.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('ID: ${jamaah.id}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _navigateToForm(jamaah), tooltip: 'Edit'),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(jamaah), tooltip: 'Hapus'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
