class Jamaah {
  final String id;
  final String nama;
  final String foto;
  final String statusAktif;

  Jamaah({
    required this.id,
    required this.nama,
    required this.foto,
    required this.statusAktif,
  });

  factory Jamaah.fromJson(Map<String, dynamic> json) {
    return Jamaah(
      id: json['id'].toString(),
      nama: json['nama'],
      foto: json['foto'],
      statusAktif: json['status_aktif'].toString(),
    );
  }
}
