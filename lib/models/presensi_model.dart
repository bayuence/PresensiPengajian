class PresensiModel {
  final String id;
  final String jamaahId;
  final String status;
  final String createdAt;

  PresensiModel({
    required this.id,
    required this.jamaahId,
    required this.status,
    required this.createdAt,
  });

  factory PresensiModel.fromJson(Map<String, dynamic> json) {
    return PresensiModel(
      id: json['id'].toString(),
      jamaahId: json['jamaah_id'].toString(),
      status: json['status'],
      createdAt: json['created_at'],
    );
  }
}
