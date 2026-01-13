# Backend PHP untuk Presensi Pengajian

## Cara Penggunaan

1. **Copy semua file PHP** ke folder `C:\xampp\htdocs\presensi_pengajian\`
2. **Buat folder `uploads`** di `C:\xampp\htdocs\presensi_pengajian\uploads\`
3. **Buat database** dengan nama `presensi_pengajian`
4. **Jalankan SQL** berikut di phpMyAdmin:

```sql
CREATE DATABASE IF NOT EXISTS presensi_pengajian;
USE presensi_pengajian;

-- Tabel Jamaah
CREATE TABLE jamaah (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nama VARCHAR(100) NOT NULL,
    foto VARCHAR(255) NULL
);

-- Tabel Presensi
CREATE TABLE presensi (
    id INT PRIMARY KEY AUTO_INCREMENT,
    jamaah_id INT NOT NULL,
    status ENUM('Hadir', 'Tidak Hadir', 'Izin', 'Sakit') DEFAULT 'Tidak Hadir',
    tanggal DATE NOT NULL,
    waktu TIME NULL,
    keterangan TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (jamaah_id) REFERENCES jamaah(id) ON DELETE CASCADE
);
```

## Struktur Folder di htdocs

```
C:\xampp\htdocs\presensi_pengajian\
├── config.php
├── jamaah.php
├── presensi.php
└── uploads/
    └── (foto jamaah akan disimpan di sini)
```

## API Endpoints

### Jamaah
- **GET** `/jamaah.php` - Ambil semua data jamaah
- **POST** `/jamaah.php` - Tambah jamaah baru (dengan foto)
- **PUT** `/jamaah.php` - Update jamaah (via POST dengan _method=PUT)
- **DELETE** `/jamaah.php` - Hapus jamaah

### Presensi
- **GET** `/presensi.php?tanggal=2026-01-13` - Ambil presensi berdasarkan tanggal
- **POST** `/presensi.php` - Submit/update presensi

## Konfigurasi Flutter

Update IP address di controller Flutter sesuai IP PC kamu:
- File: `lib/controllers/jamaah_controller.dart`
- File: `lib/controllers/presensi_controller.dart`
- File: `lib/views/jamaah_view.dart`
- File: `lib/views/tambah_jamaah_page.dart`

Contoh: Ganti `localhost` dengan `10.10.10.47` (sesuai IP PC)
