# Presensi Pengajian

Aplikasi presensi digital untuk pengajian. Dikembangkan sebagai proyek UAS mata kuliah Pemrograman Mobile.

## Tentang Aplikasi

Aplikasi ini membantu pengurus pengajian mencatat kehadiran jamaah secara digital. Konsepnya sederhana: pengurus yang memegang kontrol penuh, jamaah tidak perlu scan QR atau login sendiri.

Kenapa dibuat begini? Karena jamaah pengajian beragam usianya, tidak semua familiar dengan smartphone. Jadi lebih praktis kalau pengurus yang input semua.

## Fitur

**Yang sudah jalan:**
- Login untuk pengurus
- Kelola data jamaah (tambah, edit, hapus)
- Ambil foto jamaah pakai kamera
- Input presensi per sesi pengajian
- Rekap kehadiran dengan filter tanggal
- Logout

**Rencana ke depan:**
- Export laporan ke PDF/Excel
- Notifikasi pengingat
- Support multiple pengajian

## Tech Stack

| Komponen | Teknologi |
|----------|-----------|
| Mobile | Flutter |
| Backend | PHP |
| Database | MySQL |
| Server Lokal | XAMPP |

## Struktur Folder

```
lib/
├── config/        # Konfigurasi API
├── controllers/   # Logic bisnis
├── models/        # Model data
├── services/      # Session, dll
├── views/         # Halaman UI
│   ├── auth/      # Login
│   ├── home/      # Dashboard
│   ├── jamaah/    # Kelola jamaah
│   ├── presensi/  # Input & rekap presensi
│   └── profil/    # Profil & logout
└── main.dart

DOCPHPhtdoc/       # Backend PHP
├── config.php
├── auth.php
├── jamaah.php
└── presensi.php
```

## Cara Pakai

### 1. Setup Backend

Copy folder `DOCPHPhtdoc` ke `C:\xampp\htdocs\presensi_pengajian\`

Buat database di phpMyAdmin, import tabel yang diperlukan.

### 2. Jalankan Aplikasi

```bash
flutter pub get
flutter run
```

### 3. Konfigurasi API

Kalau pakai device fisik, update IP di `lib/config/api.dart` sesuai IP laptop kamu.

## Troubleshooting

**Gagal konek ke server?**
- Cek XAMPP sudah running (Apache + MySQL)
- Coba akses `http://localhost/presensi_pengajian/jamaah.php` di browser

**Data tidak muncul?**
- Pastikan database sudah dibuat
- Cek koneksi di `config.php`

**Error di HP Android?**
- Ganti `localhost` jadi IP laptop (contoh: `192.168.1.100`)
- HP dan laptop harus satu jaringan WiFi

## Dokumentasi

- [PRD di Notion](https://www.notion.so/PRD-Presensi-Pengajian-2e1db46c3ddf807f9943d3613d699ade)

## Status

Dalam pengembangan aktif untuk UAS Semester ini.

---

Proyek UAS Pemrograman Mobile
