class AccountUser {
  final int id;
  final String username;
  final String nama;

  AccountUser({required this.id, required this.username, required this.nama});

  factory AccountUser.fromJson(Map<String, dynamic> json) {
    return AccountUser(
      id: json['id'],
      username: json['username'] ?? '',
      nama: json['nama'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'username': username, 'nama': nama};
  }
}
