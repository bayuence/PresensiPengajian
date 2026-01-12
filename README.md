# Presensi Pengajian – Mobile App

Aplikasi mobile presensi pengajian yang dikembangkan sebagai proyek
Ujian Akhir Semester (UAS) mata kuliah Pengembangan Aplikasi Mobile.

Aplikasi ini dirancang untuk membantu pengurus pengajian dalam
mengelola kehadiran jamaah secara digital dengan sistem kontrol terpusat,
tanpa melibatkan presensi mandiri oleh jamaah.

---

## 🚀 Quick Start

```bash
# 1. Setup Backend
# Copy folder backend ke: C:\xampp\htdocs\presensi_pengajian\
# Import database.sql ke MySQL
# Test: http://localhost/presensi_pengajian/jamaah.php

# 2. Setup Flutter
cd presensi_pengajian
flutter pub get
flutter run
```

**Dokumentasi lengkap:** [QUICKSTART.md](../QUICKSTART.md) | [SETUP.md](../SETUP.md)

---

## 📱 Fitur Utama

### ✅ Menu Presensi
- Menampilkan daftar jamaah
- Tombol ✔ Hadir / ✖ Izin
- Menyimpan ke database (transaksi)
- Real-time feedback

### 📊 Menu Data Jamaah
- CRUD data jamaah
- Status aktif/nonaktif
- Siap untuk tambah foto
- Clean separation dari presensi

---

## 🏗️ Teknologi

- **Frontend:** Flutter 3.32.1
- **Backend:** PHP + MySQL
- **Server:** XAMPP
- **Architecture:** MVC Pattern
- **Code Style:** Clean Code

---

## 📂 Struktur Proyek

```
lib/
├── config/          # API Configuration
├── models/          # Data Models
├── controllers/     # Business Logic
├── views/           # UI Screens
└── main.dart        # Entry Point

backend/
├── config.php       # Database Config
├── jamaah.php       # CRUD Jamaah API
├── presensi_*.php   # Presensi API
└── database.sql     # Database Schema
```

**Penjelasan Clean Code:** [CLEAN_CODE.md](../CLEAN_CODE.md)

---

## 🎯 Konsep Aplikasi

### Pemisahan yang Jelas:

**Data Master vs Transaksi:**
- `jamaah` → Master data (CRUD di Menu Data Jamaah)
- `presensi` → Transaksi (Input di Menu Presensi)

**No Mixed Concerns:**
- Tidak ada status presensi di tabel jamaah
- Tidak ada tombol presensi di halaman data jamaah
- Fokus clear di setiap menu

---

## 📖 Dokumentasi

- 📘 [Quick Start](../QUICKSTART.md) - Setup cepat 5 menit
- 📙 [Setup Guide](../SETUP.md) - Panduan lengkap + troubleshooting
- 📗 [Clean Code](../CLEAN_CODE.md) - Penjelasan struktur & best practice
- 📕 [Backend API](../backend/README.md) - Dokumentasi API endpoints

---

## 💡 Fitur Mendatang

- [ ] Login pengurus
- [ ] Ambil & simpan foto jamaah
- [ ] Laporan kehadiran
- [ ] Export ke Excel/PDF
- [ ] Notifikasi presensi
- [ ] Kelola multiple pengajian

---

## 🐛 Troubleshooting

**Error koneksi?**
- Pastikan XAMPP Apache & MySQL running
- Test backend: `http://localhost/presensi_pengajian/jamaah.php`
- Kalau pakai HP: ganti `localhost` di `api_config.dart` dengan IP laptop

**Tidak ada data?**
- Import file `database.sql` ke phpMyAdmin
- Pastikan database `presensi_pengajian` sudah ada

**Error 500?**
- Cek `config.php` - username/password MySQL
- Default: username=`root`, password=(kosong)

---

## 👨‍💻 Development

```bash
# Run app
flutter run

# Format code
flutter format .

# Analyze code
flutter analyze

# Clean build
flutter clean
flutter pub get
```

---

## 📞 Status Proyek

🟢 **Active Development** - UAS Pengembangan Aplikasi Mobile

- **Product Requirements:** [Notion PRD](https://www.notion.so/PRD-Presensi-Pengajian-2e1db46c3ddf807f9943d3613d699ade)
- **Repository:** [GitHub](https://github.com/bayuence/PresensiPengajian)

---

Dibuat dengan 💚 untuk proyek UAS
