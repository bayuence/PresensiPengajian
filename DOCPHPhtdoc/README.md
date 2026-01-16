
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

