<?php
require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        getPresensiList();
        break;
    case 'POST':
        submitPresensi();
        break;
    default:
        echo json_encode(['success' => false, 'message' => 'Method tidak diizinkan']);
        break;
}

// Fungsi GET - Ambil list presensi
function getPresensiList() {
    global $conn;
    
    // Ambil parameter tanggal (default hari ini)
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
    if ($result->num_rows > 0) {
        while($row = $result->fetch_assoc()) {
            $presensi[] = [
                'id' => (int)$row['id'],
                'jamaahId' => (int)$row['jamaah_id'],
                'jamaahNama' => $row['jamaah_nama'],
                'jamaahFoto' => $row['jamaah_foto'],
                'status' => $row['status'],
                'tanggal' => $row['tanggal'],
                'waktu' => $row['waktu'],
                'keterangan' => $row['keterangan']
            ];
        }
    }
    
    echo json_encode([
        'success' => true,
        'data' => $presensi,
        'tanggal' => $tanggal
    ]);
    
    $stmt->close();
}

// Fungsi POST - Submit/update presensi
function submitPresensi() {
    global $conn;
    
    $jamaah_id = $_POST['jamaah_id'] ?? 0;
    $status = $_POST['status'] ?? 'Tidak Hadir';
    $tanggal = $_POST['tanggal'] ?? date('Y-m-d');
    $waktu = $_POST['waktu'] ?? date('H:i:s');
    $keterangan = $_POST['keterangan'] ?? '';
    
    if (empty($jamaah_id)) {
        echo json_encode(['success' => false, 'message' => 'Jamaah ID harus diisi']);
        return;
    }
    
    // Cek apakah sudah presensi hari ini
    $check_sql = "SELECT id FROM presensi WHERE jamaah_id = ? AND tanggal = ?";
    $check_stmt = $conn->prepare($check_sql);
    $check_stmt->bind_param("is", $jamaah_id, $tanggal);
    $check_stmt->execute();
    $check_result = $check_stmt->get_result();
    
    if ($check_result->num_rows > 0) {
        // Sudah ada, update
        $row = $check_result->fetch_assoc();
        $update_sql = "UPDATE presensi SET status = ?, waktu = ?, keterangan = ? WHERE id = ?";
        $update_stmt = $conn->prepare($update_sql);
        $update_stmt->bind_param("sssi", $status, $waktu, $keterangan, $row['id']);
        
        if ($update_stmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'Presensi berhasil diupdate',
                'id' => $row['id']
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Gagal update: ' . $conn->error
            ]);
        }
        $update_stmt->close();
    } else {
        // Belum ada, insert baru
        $insert_sql = "INSERT INTO presensi (jamaah_id, status, tanggal, waktu, keterangan) VALUES (?, ?, ?, ?, ?)";
        $insert_stmt = $conn->prepare($insert_sql);
        $insert_stmt->bind_param("issss", $jamaah_id, $status, $tanggal, $waktu, $keterangan);
        
        if ($insert_stmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'Presensi berhasil disimpan',
                'id' => $conn->insert_id
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Gagal menyimpan: ' . $conn->error
            ]);
        }
        $insert_stmt->close();
    }
    
    $check_stmt->close();
}

$conn->close();
?>
