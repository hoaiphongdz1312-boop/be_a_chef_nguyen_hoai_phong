import 'dart:typed_data';

/// Học viên đã đăng ký khuôn mặt.
class Learner {
  const Learner({
    required this.id,
    required this.name,
    required this.embedding,
    required this.sampleCount,
    required this.createdAt,
  });

  final int id;
  final String name;

  /// Vector đặc trưng trung bình, đã chuẩn hóa L2.
  final Float32List embedding;
  final int sampleCount;
  final DateTime createdAt;

  factory Learner.fromMap(Map<String, Object?> map) {
    final blob = map['embedding']! as Uint8List;
    // Chép sang buffer mới để chắc chắn căn lề 4 byte cho Float32List.
    final embedding = Uint8List.fromList(blob).buffer.asFloat32List();
    return Learner(
      id: map['id']! as int,
      name: map['name']! as String,
      embedding: embedding,
      sampleCount: map['sample_count']! as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
    );
  }
}
