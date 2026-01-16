<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'config.php';

$method = $_SERVER['REQUEST_METHOD'];
$action = isset($_GET['action']) ? $_GET['action'] : '';

//LOGIN 
if ($method === 'POST' && $action === 'login') {
    $username = isset($_POST['username']) ? trim($_POST['username']) : '';
    $password = isset($_POST['password']) ? trim($_POST['password']) : '';
    
    if (empty($username) || empty($password)) {
        echo json_encode([
            "success" => false,
            "message" => "Username dan password harus diisi"
        ]);
        exit;
    }
    
    $stmt = $conn->prepare("SELECT id, username, nama, password FROM users WHERE username = ?");
    $stmt->bind_param("s", $username);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();
        
        // Cek password
        if ($password === $user['password']) {
            echo json_encode([
                "success" => true,
                "message" => "Login berhasil",
                "data" => [
                    "id" => $user['id'],
                    "username" => $user['username'],
                    "nama" => $user['nama']
                ]
            ]);
        } else {
            echo json_encode([
                "success" => false,
                "message" => "Password salah"
            ]);
        }
    } else {
        echo json_encode([
            "success" => false,
            "message" => "Username tidak ditemukan"
        ]);
    }
    
    $stmt->close();
    exit;
}

//CEK USER (opsional)
if ($method === 'GET' && $action === 'check') {
    $user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
    
    if ($user_id <= 0) {
        echo json_encode([
            "success" => false,
            "message" => "User ID tidak valid"
        ]);
        exit;
    }
    
    $stmt = $conn->prepare("SELECT id, username, nama FROM users WHERE id = ?");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();
        echo json_encode([
            "success" => true,
            "data" => $user
        ]);
    } else {
        echo json_encode([
            "success" => false,
            "message" => "User tidak ditemukan"
        ]);
    }
    
    $stmt->close();
    exit;
}

// Default response
echo json_encode([
    "success" => false,
    "message" => "Action tidak valid"
]);

$conn->close();
?>
