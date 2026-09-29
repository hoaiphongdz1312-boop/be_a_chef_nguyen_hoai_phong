/// Tiến độ của một học viên với một món.
class LessonProgress {
  const LessonProgress({
    required this.learnerId,
    required this.lessonId,
    required this.completedSteps,
    required this.isCompleted,
    required this.updatedAt,
    this.completedAt,
  });

  final int learnerId;
  final String lessonId;

  /// Số bước đã xong (cũng là chỉ số của bước đang học tiếp theo).
  final int completedSteps;
  final bool isCompleted;
  final DateTime updatedAt;
  final DateTime? completedAt;

  /// Đang học dở: đã làm ít nhất 1 bước nhưng chưa hoàn thành.
  bool get isInProgress => completedSteps > 0 && !isCompleted;

  /// Tỉ lệ hoàn thành 0.0–1.0 so với tổng số bước.
  double fraction(int totalSteps) =>
      totalSteps == 0 ? 0 : (completedSteps / totalSteps).clamp(0.0, 1.0);

  factory LessonProgress.fromMap(Map<String, Object?> map) {
    final completedAt = map['completed_at'] as int?;
    return LessonProgress(
      learnerId: map['learner_id']! as int,
      lessonId: map['lesson_id']! as String,
      completedSteps: map['completed_steps']! as int,
      isCompleted: (map['is_completed']! as int) == 1,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
      completedAt: completedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(completedAt),
    );
  }

  Map<String, Object?> toMap() => {
        'learner_id': learnerId,
        'lesson_id': lessonId,
        'completed_steps': completedSteps,
        'is_completed': isCompleted ? 1 : 0,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'completed_at': completedAt?.millisecondsSinceEpoch,
      };
}
