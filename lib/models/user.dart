class User {
  final int id;
  final String username;
  final String nama;

  User({required this.id, required this.username, required this.nama});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'] ?? '',
      nama: json['nama'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'username': username, 'nama': nama};
  }
}
