import 'package:flutter/material.dart';
import '../controllers/presensi_controller.dart';
import '../models/presensi_model.dart';

class PresensiPage extends StatefulWidget {
  const PresensiPage({super.key});

  @override
  State<PresensiPage> createState() => _PresensiPageState();
}

class _PresensiPageState extends State<PresensiPage> {
  List<PresensiModel> presensi = [];
  bool loading = true;

  Future<void> loadData() async {
    try {
      final data = await PresensiController.fetchPresensi();
      setState(() {
        presensi = data;
        loading = false;
      });
    } catch (e) {
      loading = false;
    }
  }

  Future<void> submitPresensi(int jamaahId, String status) async {
    await PresensiController.submitPresensi(jamaahId: jamaahId, status: status);
    loadData(); // refresh
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Presensi Jamaah")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: presensi.length,
              itemBuilder: (context, index) {
                final item = presensi[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(item.jamaahNama),
                    subtitle: Text(
                      "${item.tanggal} ${item.waktu ?? ''}\nStatus: ${item.status}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          onPressed: () {
                            submitPresensi(item.jamaahId, "Hadir");
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            submitPresensi(item.jamaahId, "Izin");
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
