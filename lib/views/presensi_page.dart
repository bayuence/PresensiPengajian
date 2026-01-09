import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/presensi_model.dart';

class PresensiPage extends StatefulWidget {
  const PresensiPage({super.key});

  @override
  State<PresensiPage> createState() => _PresensiPageState();
}

class _PresensiPageState extends State<PresensiPage> {
  List<PresensiModel> presensi = [];
  bool loading = true;

  Future<void> fetchPresensi() async {
    final url = Uri.parse(
      "http://localhost/presensi_pengajian/presensi_list.php",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List list = jsonData['data'];

      setState(() {
        presensi = list.map((e) => PresensiModel.fromJson(e)).toList();
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPresensi();
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
