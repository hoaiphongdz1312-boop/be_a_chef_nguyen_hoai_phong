import '../data/models/lesson.dart';
import '../data/models/lesson_progress.dart';

/// Lý do đưa ra gợi ý (để hiển thị lời giải thích ngắn trên dashboard).
enum RecommendationReason {
  /// Món đang học dở, cập nhật gần nhất.
  continueLearning,

  /// Món chưa học, cùng độ khó cao nhất đã hoàn thành.
  sameLevel,

  /// Món chưa học, khó hơn một bậc so với mức đã hoàn thành.
  nextLevel,

  /// Người mới: món dễ nhất.
  beginner,

  /// Không có món đúng mức → món chưa học dễ nhất còn lại.
  remaining,
}

class Recommendation {
  const Recommendation(this.lesson, this.reason);

  final Lesson lesson;
  final RecommendationReason reason;
}

/// Gợi ý bài học tiếp theo theo luật (hàm thuần, không truy cập DB):
///
/// 1. Có món đang học dở → món có `updatedAt` mới nhất.
/// 2. Đã hoàn thành ít nhất 1 món, gọi D = độ khó cao nhất đã hoàn thành →
///    món chưa học có độ khó D; nếu hết thì độ khó D + 1.
/// 3. Người mới (chưa hoàn thành món nào) → món dễ nhất.
/// 4. Không còn món nào khớp luật 2 → món chưa học dễ nhất còn lại.
/// 5. Đã học hết tất cả → `null`.
///
/// Khi hòa, chọn món có `sortOrder` nhỏ hơn (thứ tự trong lessons.json).
abstract final class RecommendationService {
  static Recommendation? recommend(
    List<Lesson> lessons,
    List<LessonProgress> progress,
  ) {
    final byId = {for (final l in lessons) l.id: l};
    final progressById = {
      for (final p in progress)
        if (byId.containsKey(p.lessonId)) p.lessonId: p,
    };

    // 1. Món đang học dở, mới nhất trước.
    final inProgress = progressById.values.where((p) => p.isInProgress).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (inProgress.isNotEmpty) {
      return Recommendation(
        byId[inProgress.first.lessonId]!,
        RecommendationReason.continueLearning,
      );
    }

    // Món chưa học: chưa có tiến độ hoặc chưa xong bước nào.
    final notStarted = [
      for (final l in lessons)
        if ((progressById[l.id]?.completedSteps ?? 0) == 0 &&
            progressById[l.id]?.isCompleted != true)
          l,
    ]..sort(_easiestFirst);
    if (notStarted.isEmpty) return null;

    final completed = [
      for (final p in progressById.values)
        if (p.isCompleted) byId[p.lessonId]!,
    ];

    // 3. Người mới.
    if (completed.isEmpty) {
      return Recommendation(notStarted.first, RecommendationReason.beginner);
    }

    // 2. Cùng mức hoặc khó hơn một bậc.
    final maxDone =
        completed.map((l) => l.difficulty).reduce((a, b) => a > b ? a : b);
    for (final (level, reason) in [
      (maxDone, RecommendationReason.sameLevel),
      (maxDone + 1, RecommendationReason.nextLevel),
    ]) {
      final match = notStarted.where((l) => l.difficulty == level);
      if (match.isNotEmpty) return Recommendation(match.first, reason);
    }

    // 4. Còn lại.
    return Recommendation(notStarted.first, RecommendationReason.remaining);
  }

  static int _easiestFirst(Lesson a, Lesson b) {
    final byDifficulty = a.difficulty.compareTo(b.difficulty);
    return byDifficulty != 0 ? byDifficulty : a.sortOrder.compareTo(b.sortOrder);
  }
}

extension RecommendationReasonText on RecommendationReason {
  String get message => switch (this) {
        RecommendationReason.continueLearning => 'Tiếp tục món bạn đang học dở',
        RecommendationReason.sameLevel => 'Củng cố tay nghề ở mức hiện tại',
        RecommendationReason.nextLevel => 'Sẵn sàng thử thách khó hơn',
        RecommendationReason.beginner => 'Bắt đầu với món dễ nhất',
        RecommendationReason.remaining => 'Món bạn chưa thử',
      };
}
