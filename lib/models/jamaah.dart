class Jamaah {
  final String id;
  final String nama;
  final String foto;
  final String statusAktif;
  final String createdAt;

  String presensiStatus;

  Jamaah({
    required this.id,
    required this.nama,
    required this.foto,
    required this.statusAktif,
    required this.createdAt,
    this.presensiStatus = 'Tidak Hadir',
  });

  factory Jamaah.fromJson(Map<String, dynamic> json) {
    return Jamaah(
      id: json['id'],
      nama: json['nama'],
      foto: json['foto'],
      statusAktif: json['status_aktif'],
      createdAt: json['created_at'],
    );
  }
}
