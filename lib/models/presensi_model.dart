class PresensiModel {
  final int id;
  final int jamaahId;
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
      id: int.parse(json['id'].toString()),
      jamaahId: int.parse(json['jamaah_id'].toString()),
      status: json['status'],
      createdAt: json['created_at'],
    );
  }
}
