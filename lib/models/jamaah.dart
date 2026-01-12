class Jamaah {
  final int id;
  final String nama;
  final String? foto;

  Jamaah({
    required this.id,
    required this.nama,
    this.foto,
  });

  factory Jamaah.fromJson(Map<String, dynamic> json) {
    return Jamaah(
      id: json['id'],
      nama: json['nama'],
      foto: json['foto'],
    );
  }
}
