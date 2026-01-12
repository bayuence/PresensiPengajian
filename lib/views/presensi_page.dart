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
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daftar Presensi")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: presensi.length,
              itemBuilder: (context, index) {
                final item = presensi[index];
                return ListTile(
                  title: Text("Jamaah ID: ${item.jamaahId}"),
                  subtitle: Text("Status: ${item.status}"),
                );
              },
            ),
    );
  }
}
