<?php
require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

switch ($method) {
    case 'GET':
        if ($action === 'sesi') {
            getSesiList();
        } else if ($action === 'detail') {
            getPresensiDetail();
        } else {
            getPresensiList();
        }
        break;
    case 'POST':
        if ($action === 'mulai') {
            mulaiSesi();
        } else if ($action === 'akhiri') {
            akhiriSesi();
        } else if ($action === 'hapus') {
            hapusSesi();
        } else {
            submitPresensi();
        }
        break;
    default:
        echo json_encode(['success' => false, 'message' => 'Method tidak diizinkan']);
        break;
}

// ========== SESI FUNCTIONS ==========

// GET - Ambil list sesi hari ini
function getSesiList() {
    global $conn;
    
    $tanggal = $_GET['tanggal'] ?? date('Y-m-d');
    
    $sql = "SELECT s.*, 
            (SELECT COUNT(*) FROM presensi p WHERE p.sesi_id = s.id AND p.status = 'Hadir') as jumlah_hadir,
            (SELECT COUNT(*) FROM presensi p WHERE p.sesi_id = s.id AND p.status = 'Izin') as jumlah_izin,
            (SELECT COUNT(*) FROM presensi p WHERE p.sesi_id = s.id AND p.status = 'Tidak Hadir') as jumlah_tidak_hadir
            FROM sesi_presensi s
            WHERE s.tanggal = ?
            ORDER BY s.waktu_mulai DESC";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $tanggal);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $sesi = [];
    while ($row = $result->fetch_assoc()) {
        $sesi[] = [
            'id' => (int)$row['id'],
            'namaPengajian' => $row['nama_pengajian'],
            'tanggal' => $row['tanggal'],
            'waktuMulai' => $row['waktu_mulai'],
            'waktuSelesai' => $row['waktu_selesai'],
            'status' => $row['status'],
            'jumlahHadir' => (int)$row['jumlah_hadir'],
            'jumlahIzin' => (int)$row['jumlah_izin'],
            'jumlahTidakHadir' => (int)$row['jumlah_tidak_hadir']
        ];
    }
    
    echo json_encode([
        'success' => true,
        'data' => $sesi,
        'tanggal' => $tanggal
    ]);
    
    $stmt->close();
}

// POST - Mulai sesi baru
function mulaiSesi() {
    global $conn;
    
    $nama_pengajian = $_POST['nama_pengajian'] ?? '';
    $tanggal = $_POST['tanggal'] ?? date('Y-m-d');
    $waktu_mulai = $_POST['waktu_mulai'] ?? date('H:i:s');
    
    if (empty($nama_pengajian)) {
        echo json_encode(['success' => false, 'message' => 'Nama pengajian harus diisi']);
        return;
    }
    
    $stmt = $conn->prepare("INSERT INTO sesi_presensi (nama_pengajian, tanggal, waktu_mulai, status) VALUES (?, ?, ?, 'berlangsung')");
    $stmt->bind_param("sss", $nama_pengajian, $tanggal, $waktu_mulai);
    
    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Sesi presensi dimulai',
            'id' => $conn->insert_id
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Gagal memulai sesi: ' . $conn->error
        ]);
    }
    
    $stmt->close();
}

// POST - Akhiri sesi (set yang belum presensi jadi Tidak Hadir)
function akhiriSesi() {
    global $conn;
    
    $sesi_id = $_POST['sesi_id'] ?? 0;
    
    if (empty($sesi_id)) {
        echo json_encode(['success' => false, 'message' => 'Sesi ID harus diisi']);
        return;
    }
    
    // Ambil tanggal sesi
    $sesi_result = $conn->query("SELECT tanggal FROM sesi_presensi WHERE id = $sesi_id");
    $sesi_data = $sesi_result->fetch_assoc();
    $tanggal = $sesi_data['tanggal'];
    
    // Ambil semua jamaah yang BELUM dipresensi di sesi ini
    $sql = "SELECT j.id FROM jamaah j 
            WHERE j.id NOT IN (SELECT jamaah_id FROM presensi WHERE sesi_id = ?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $sesi_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    // Insert Tidak Hadir untuk yang belum dipresensi
    $waktu = date('H:i:s');
    while ($row = $result->fetch_assoc()) {
        $insert = $conn->prepare("INSERT INTO presensi (sesi_id, jamaah_id, status, tanggal, waktu) VALUES (?, ?, 'Tidak Hadir', ?, ?)");
        $insert->bind_param("iiss", $sesi_id, $row['id'], $tanggal, $waktu);
        $insert->execute();
        $insert->close();
    }
    $stmt->close();
    
    // Update status sesi jadi selesai
    $update = $conn->prepare("UPDATE sesi_presensi SET status = 'selesai', waktu_selesai = ? WHERE id = ?");
    $update->bind_param("si", $waktu, $sesi_id);
    
    if ($update->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Sesi presensi diakhiri'
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Gagal mengakhiri sesi'
        ]);
    }
    
    $update->close();
}

// POST - Hapus sesi presensi
function hapusSesi() {
    global $conn;
    
    $sesi_id = $_POST['sesi_id'] ?? 0;
    
    if (empty($sesi_id)) {
        echo json_encode(['success' => false, 'message' => 'Sesi ID harus diisi']);
        return;
    }
    
    // Hapus semua presensi yang terkait dengan sesi ini
    $deletePresensi = $conn->prepare("DELETE FROM presensi WHERE sesi_id = ?");
    $deletePresensi->bind_param("i", $sesi_id);
    $deletePresensi->execute();
    $deletePresensi->close();
    
    // Hapus sesi
    $deleteSesi = $conn->prepare("DELETE FROM sesi_presensi WHERE id = ?");
    $deleteSesi->bind_param("i", $sesi_id);
    
    if ($deleteSesi->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Sesi berhasil dihapus'
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Gagal menghapus sesi: ' . $conn->error
        ]);
    }
    
    $deleteSesi->close();
}

// ========== PRESENSI FUNCTIONS ==========

// GET - Ambil detail presensi per sesi
function getPresensiDetail() {
    global $conn;
    
    $sesi_id = $_GET['sesi_id'] ?? 0;
    
    // Ambil semua jamaah dengan status presensi di sesi ini
    $sql = "SELECT j.id, j.nama, j.foto, 
            COALESCE(p.status, 'Belum') as status,
            p.id as presensi_id
            FROM jamaah j
            LEFT JOIN presensi p ON j.id = p.jamaah_id AND p.sesi_id = ?
            ORDER BY j.nama ASC";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $sesi_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $data = [];
    while ($row = $result->fetch_assoc()) {
        $data[] = [
            'jamaahId' => (int)$row['id'],
            'nama' => $row['nama'],
            'foto' => $row['foto'],
            'status' => $row['status'],
            'presensiId' => $row['presensi_id'] ? (int)$row['presensi_id'] : null
        ];
    }
    
    echo json_encode([
        'success' => true,
        'data' => $data
    ]);
    
    $stmt->close();
}

// GET - Ambil list presensi (legacy)
function getPresensiList() {
    global $conn;
    
    $tanggal = $_GET['tanggal'] ?? date('Y-m-d');
    
    $sql = "SELECT p.*, j.nama as jamaah_nama, j.foto as jamaah_foto
            FROM presensi p
            INNER JOIN jamaah j ON p.jamaah_id = j.id
            WHERE p.tanggal = ?
            ORDER BY p.created_at DESC";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $tanggal);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $presensi = [];
    while($row = $result->fetch_assoc()) {
        $presensi[] = [
            'id' => (int)$row['id'],
            'sesiId' => $row['sesi_id'] ? (int)$row['sesi_id'] : null,
            'jamaahId' => (int)$row['jamaah_id'],
            'jamaahNama' => $row['jamaah_nama'],
            'jamaahFoto' => $row['jamaah_foto'],
            'status' => $row['status'],
            'tanggal' => $row['tanggal'],
            'waktu' => $row['waktu'],
            'keterangan' => $row['keterangan']
        ];
    }
    
    echo json_encode([
        'success' => true,
        'data' => $presensi,
        'tanggal' => $tanggal
    ]);
    
    $stmt->close();
}

// POST - Submit presensi (Hadir/Izin)
function submitPresensi() {
    global $conn;
    
    $sesi_id = $_POST['sesi_id'] ?? 0;
    $jamaah_id = $_POST['jamaah_id'] ?? 0;
    $status = $_POST['status'] ?? 'Hadir';
    $tanggal = $_POST['tanggal'] ?? date('Y-m-d');
    $waktu = $_POST['waktu'] ?? date('H:i:s');
    
    if (empty($sesi_id) || empty($jamaah_id)) {
        echo json_encode(['success' => false, 'message' => 'Sesi ID dan Jamaah ID harus diisi']);
        return;
    }
    
    // Cek apakah sudah ada presensi di sesi ini
    $check = $conn->prepare("SELECT id FROM presensi WHERE sesi_id = ? AND jamaah_id = ?");
    $check->bind_param("ii", $sesi_id, $jamaah_id);
    $check->execute();
    $check_result = $check->get_result();
    
    if ($check_result->num_rows > 0) {
        // Update
        $row = $check_result->fetch_assoc();
        $stmt = $conn->prepare("UPDATE presensi SET status = ?, waktu = ? WHERE id = ?");
        $stmt->bind_param("ssi", $status, $waktu, $row['id']);
    } else {
        // Insert
        $stmt = $conn->prepare("INSERT INTO presensi (sesi_id, jamaah_id, status, tanggal, waktu) VALUES (?, ?, ?, ?, ?)");
        $stmt->bind_param("iisss", $sesi_id, $jamaah_id, $status, $tanggal, $waktu);
    }
    $check->close();
    
    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Presensi berhasil disimpan'
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Gagal menyimpan: ' . $conn->error
        ]);
    }
    
    $stmt->close();
}

$conn->close();
?>
