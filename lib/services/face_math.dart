import 'dart:math' as math;
import 'dart:typed_data';

/// Các hàm thuần cho vector embedding khuôn mặt (không phụ thuộc Flutter,
/// test được trên máy tính).

/// Chuẩn hóa L2: trả về vector cùng hướng có độ dài 1.
/// Vector toàn 0 được trả về nguyên trạng (không chia cho 0).
Float32List l2Normalize(List<double> v) {
  var sumSq = 0.0;
  for (final x in v) {
    sumSq += x * x;
  }
  final out = Float32List(v.length);
  if (sumSq == 0) return out;
  final inv = 1 / math.sqrt(sumSq);
  for (var i = 0; i < v.length; i++) {
    out[i] = v[i] * inv;
  }
  return out;
}

/// Độ giống cosine trong khoảng [-1, 1].
/// Không giả định đầu vào đã chuẩn hóa. Trả về 0 nếu một vector toàn 0.
double cosineSimilarity(List<double> a, List<double> b) {
  if (a.length != b.length) {
    throw ArgumentError('Khác số chiều: ${a.length} và ${b.length}');
  }
  var dot = 0.0, na = 0.0, nb = 0.0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  if (na == 0 || nb == 0) return 0;
  return dot / (math.sqrt(na) * math.sqrt(nb));
}

/// Vector đại diện khi đăng ký: chuẩn hóa từng mẫu, lấy trung bình,
/// rồi chuẩn hóa lại (để mỗi mẫu đóng góp như nhau).
Float32List averageEmbedding(List<List<double>> samples) {
  if (samples.isEmpty) throw ArgumentError('Cần ít nhất 1 mẫu');
  final dim = samples.first.length;
  final sum = Float64List(dim);
  for (final s in samples) {
    if (s.length != dim) throw ArgumentError('Các mẫu khác số chiều');
    final n = l2Normalize(s);
    for (var i = 0; i < dim; i++) {
      sum[i] += n[i];
    }
  }
  return l2Normalize(sum);
}

/// Kết quả so khớp: ứng viên giống nhất và độ giống của nó.
class MatchResult<T> {
  const MatchResult(this.candidate, this.score, {required this.accepted});

  final T candidate;
  final double score;

  /// `true` nếu [score] đạt ngưỡng.
  final bool accepted;
}

/// Tìm ứng viên có độ giống cosine cao nhất với [query].
///
/// Luôn trả về ứng viên tốt nhất (để ghi debug log), kèm cờ [MatchResult.accepted]
/// cho biết có đạt [threshold] hay không. Trả về `null` khi không có ứng viên.
MatchResult<T>? findBestMatch<T>(
  List<double> query,
  Iterable<T> candidates,
  List<double> Function(T) embeddingOf, {
  required double threshold,
}) {
  MatchResult<T>? best;
  for (final c in candidates) {
    final score = cosineSimilarity(query, embeddingOf(c));
    if (best == null || score > best.score) {
      best = MatchResult(c, score, accepted: score >= threshold);
    }
  }
  return best;
}
