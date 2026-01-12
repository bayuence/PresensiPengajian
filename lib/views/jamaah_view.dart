import 'package:flutter/material.dart';
import '../controllers/jamaah_controller.dart';
import '../models/jamaah.dart';

class JamaahView extends StatefulWidget {
  const JamaahView({super.key});

  @override
  State<JamaahView> createState() => _JamaahViewState();
}

class _JamaahViewState extends State<JamaahView> {
  late Future<List<Jamaah>> futureJamaah;

  @override
  void initState() {
    super.initState();
    futureJamaah = JamaahController.fetchJamaahModel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Jamaah')),
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

          return ListView.builder(
            itemCount: jamaahList.length,
            itemBuilder: (context, index) {
              final jamaah = jamaahList[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(jamaah.nama),
                  subtitle: Text('ID: ${jamaah.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
