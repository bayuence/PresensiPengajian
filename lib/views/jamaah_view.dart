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
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(jamaahList[index].nama),
                  subtitle: Text('Status: ${jamaahList[index].presensiStatus}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          setState(() {
                            jamaahList[index].presensiStatus = 'Hadir';
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            jamaahList[index].presensiStatus = 'Izin';
                          });
                        },
                      ),
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
