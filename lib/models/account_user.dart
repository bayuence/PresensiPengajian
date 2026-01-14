class AccountUser {
  final int id;
  final String username;
  final String nama;
  final String? role;

  AccountUser({
    required this.id, 
    required this.username, 
    required this.nama,
    this.role,
  });

  factory AccountUser.fromJson(Map<String, dynamic> json) {
    return AccountUser(
      id: json['id'],
      username: json['username'] ?? '',
      nama: json['nama'] ?? '',
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, 
      'username': username, 
      'nama': nama,
      'role': role,
    };
  }
}
