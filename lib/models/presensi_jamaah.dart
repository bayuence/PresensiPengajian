//PRESENSI MODEL (LEGACY)
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

//SESI PRESENSI
class SesiPresensi {
  final int id;
  final String namaPengajian;
  final String tanggal;
  final String waktuMulai;
  final String? waktuSelesai;
  final String status; // 'berlangsung' atau 'selesai'
  final int jumlahHadir;
  final int jumlahIzin;
  final int jumlahTidakHadir;

  SesiPresensi({
    required this.id,
    required this.namaPengajian,
    required this.tanggal,
    required this.waktuMulai,
    this.waktuSelesai,
    required this.status,
    this.jumlahHadir = 0,
    this.jumlahIzin = 0,
    this.jumlahTidakHadir = 0,
  });

  factory SesiPresensi.fromJson(Map<String, dynamic> json) {
    return SesiPresensi(
      id: json['id'],
      namaPengajian: json['namaPengajian'] ?? '',
      tanggal: json['tanggal'] ?? '',
      waktuMulai: json['waktuMulai'] ?? '',
      waktuSelesai: json['waktuSelesai'],
      status: json['status'] ?? 'berlangsung',
      jumlahHadir: json['jumlahHadir'] ?? 0,
      jumlahIzin: json['jumlahIzin'] ?? 0,
      jumlahTidakHadir: json['jumlahTidakHadir'] ?? 0,
    );
  }

  bool get isBerlangsung => status == 'berlangsung';
  int get totalJamaah => jumlahHadir + jumlahIzin + jumlahTidakHadir;
}

// PRESENSI JAMAAH
class PresensiJamaah {
  final int jamaahId;
  final String nama;
  final String? foto;
  final String status; // 'Belum', 'Hadir', 'Izin', 'Tidak Hadir'
  final int? presensiId;
  final String? fotoBukti;

  PresensiJamaah({
    required this.jamaahId,
    required this.nama,
    this.foto,
    required this.status,
    this.presensiId,
    this.fotoBukti,
  });

  factory PresensiJamaah.fromJson(Map<String, dynamic> json) {
    return PresensiJamaah(
      jamaahId: json['jamaahId'],
      nama: json['nama'] ?? '',
      foto: json['foto'],
      status: json['status'] ?? 'Belum',
      presensiId: json['presensiId'],
      fotoBukti: json['fotoBukti'],
    );
  }

  bool get sudahPresensi => status != 'Belum';
  bool get isHadir => status == 'Hadir';
  bool get isIzin => status == 'Izin';
}
