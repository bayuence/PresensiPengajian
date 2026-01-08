import 'package:flutter/material.dart';
import '../controllers/jamaah_controller.dart';

class JamaahView extends StatelessWidget {
  const JamaahView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Jamaah')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final data = await JamaahController.fetchJamaah();
            print(data); // lihat di Debug Console
          },
          child: const Text('Ambil Data Jamaah'),
        ),
      ),
    );
  }
}
