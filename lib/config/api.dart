/// Konfigurasi API terpusat
/// Ubah baseUrl di sini untuk mengubah server API di seluruh aplikasi
class Api {
  // ============================================
  // BASE URL - Ubah di sini jika server berubah
  // ============================================
  static const String baseUrl = "http://10.10.10.47/presensi_pengajian";

  // ============================================
  // ENDPOINTS
  // ============================================
  static const String auth = "$baseUrl/auth.php";
  static const String jamaah = "$baseUrl/jamaah.php";
  static const String presensi = "$baseUrl/presensi.php";

  // ============================================
  // UPLOAD PATH
  // ============================================
  static const String uploadsDir = "$baseUrl/uploads";
  
  /// Generate URL lengkap untuk file yang diupload
  static String uploadUrl(String filename) => "$uploadsDir/$filename";

  // ============================================
  // REQUEST TIMEOUT (dalam detik)
  // ============================================
  static const int timeout = 30;

  // ============================================
  // DEFAULT HEADERS
  // ============================================
  static Map<String, String> get jsonHeaders => {
    'Content-Type': 'application/json',
  };
}
