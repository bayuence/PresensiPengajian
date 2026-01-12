class PresensiModel {
  final int id;
  final int jamaahId;
  final String jamaahNama;
  final String? jamaahFoto;
  final String status;
  final String tanggal;
  final String? waktu;
  final String? keterangan;

  PresensiModel({
    required this.id,
    required this.jamaahId,
    required this.jamaahNama,
    this.jamaahFoto,
    required this.status,
    required this.tanggal,
    this.waktu,
    this.keterangan,
  });

  factory PresensiModel.fromJson(Map<String, dynamic> json) {
    return PresensiModel(
      id: json['id'],
      jamaahId: json['jamaahId'],
      jamaahNama: json['jamaahNama'],
      jamaahFoto: json['jamaahFoto'],
      status: json['status'],
      tanggal: json['tanggal'],
      waktu: json['waktu'],
      keterangan: json['keterangan'],
    );
  }
}
