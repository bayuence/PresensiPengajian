<?php
require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

// Handle PUT via POST dengan _method field (untuk multipart/form-data)
if ($method === 'POST' && isset($_POST['_method'])) {
    $method = strtoupper($_POST['_method']);
}

switch ($method) {
    case 'GET':
        getJamaah();
        break;
    case 'POST':
        addJamaah();
        break;
    case 'PUT':
        updateJamaah();
        break;
    case 'DELETE':
        deleteJamaah();
        break;
    default:
        echo json_encode(['success' => false, 'message' => 'Method tidak diizinkan']);
        break;
}

// Fungsi GET - Ambil semua jamaah
function getJamaah() {
    global $conn;
    
    $sql = "SELECT * FROM jamaah ORDER BY nama ASC";
    $result = $conn->query($sql);
    
    $jamaah = [];
    if ($result->num_rows > 0) {
        while($row = $result->fetch_assoc()) {
            $jamaah[] = [
                'id' => (int)$row['id'],
                'nama' => $row['nama'],
                'foto' => $row['foto']
            ];
        }
    }
    
    echo json_encode([
        'success' => true,
        'data' => $jamaah
    ]);
}

// Fungsi POST - Tambah jamaah baru
function addJamaah() {
    global $conn;
    
    $nama = $_POST['nama'] ?? '';
    $foto = null;
    
    // Handle upload foto
    if (isset($_FILES['foto']) && $_FILES['foto']['error'] == 0) {
        $upload_dir = 'uploads/';
        if (!file_exists($upload_dir)) {
            mkdir($upload_dir, 0777, true);
        }
        
        $file_extension = pathinfo($_FILES['foto']['name'], PATHINFO_EXTENSION);
        $file_name = 'jamaah_' . time() . '_' . uniqid() . '.' . $file_extension;
        $upload_file = $upload_dir . $file_name;
        
        if (move_uploaded_file($_FILES['foto']['tmp_name'], $upload_file)) {
            $foto = $file_name; // HANYA nama file, bukan path lengkap
        }
    }
    
    if (empty($nama)) {
        echo json_encode(['success' => false, 'message' => 'Nama harus diisi']);
        return;
    }
    
    $stmt = $conn->prepare("INSERT INTO jamaah (nama, foto) VALUES (?, ?)");
    $stmt->bind_param("ss", $nama, $foto);
    
    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Jamaah berhasil ditambahkan',
            'id' => $conn->insert_id
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Gagal menambahkan: ' . $conn->error
        ]);
    }
    
    $stmt->close();
}

// Fungsi PUT - Update jamaah (dengan support file upload)
function updateJamaah() {
    global $conn;
    
    // Ambil dari $_POST karena dikirim via multipart/form-data
    $id = $_POST['id'] ?? 0;
    $nama = $_POST['nama'] ?? '';
    
    if (empty($id) || empty($nama)) {
        echo json_encode(['success' => false, 'message' => 'ID dan Nama harus diisi']);
        return;
    }
    
    // Cek apakah ada foto baru
    if (isset($_FILES['foto']) && $_FILES['foto']['error'] == 0) {
        $upload_dir = 'uploads/';
        if (!file_exists($upload_dir)) {
            mkdir($upload_dir, 0777, true);
        }
        
        $file_extension = pathinfo($_FILES['foto']['name'], PATHINFO_EXTENSION);
        $file_name = 'jamaah_' . time() . '_' . uniqid() . '.' . $file_extension;
        $upload_file = $upload_dir . $file_name;
        
        if (move_uploaded_file($_FILES['foto']['tmp_name'], $upload_file)) {
            // Update dengan foto baru
            $stmt = $conn->prepare("UPDATE jamaah SET nama = ?, foto = ? WHERE id = ?");
            $stmt->bind_param("ssi", $nama, $file_name, $id);
        } else {
            $stmt = $conn->prepare("UPDATE jamaah SET nama = ? WHERE id = ?");
            $stmt->bind_param("si", $nama, $id);
        }
    } else {
        // Tidak ada foto baru
        $stmt = $conn->prepare("UPDATE jamaah SET nama = ? WHERE id = ?");
        $stmt->bind_param("si", $nama, $id);
    }
    
    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Jamaah berhasil diupdate'
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Gagal update: ' . $conn->error
        ]);
    }
    
    $stmt->close();
}

// Fungsi DELETE - Hapus jamaah
function deleteJamaah() {
    global $conn;
    
    $input = json_decode(file_get_contents("php://input"), true);
    $id = $input['id'] ?? 0;
    
    if (empty($id)) {
        echo json_encode(['success' => false, 'message' => 'ID harus diisi']);
        return;
    }
    
    // Hapus foto jika ada
    $result = $conn->query("SELECT foto FROM jamaah WHERE id = $id");
    if ($row = $result->fetch_assoc()) {
        if ($row['foto']) {
            $fotoPath = 'uploads/' . $row['foto'];
            if (file_exists($fotoPath)) {
                unlink($fotoPath);
            }
        }
    }
    
    $stmt = $conn->prepare("DELETE FROM jamaah WHERE id = ?");
    $stmt->bind_param("i", $id);
    
    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Jamaah berhasil dihapus'
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Gagal menghapus: ' . $conn->error
        ]);
    }
    
    $stmt->close();
}

$conn->close();
?>
