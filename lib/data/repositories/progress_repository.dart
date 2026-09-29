import 'dart:math' as math;

import '../database.dart';
import '../models/lesson.dart';
import '../models/lesson_progress.dart';

class ProgressRepository {
  Future<List<LessonProgress>> getForLearner(int learnerId) async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'progress',
      where: 'learner_id = ?',
      whereArgs: [learnerId],
    );
    return rows.map(LessonProgress.fromMap).toList();
  }

  Future<LessonProgress?> get(int learnerId, String lessonId) async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'progress',
      where: 'learner_id = ? AND lesson_id = ?',
      whereArgs: [learnerId, lessonId],
      limit: 1,
    );
    return rows.isEmpty ? null : LessonProgress.fromMap(rows.first);
  }

  /// Đánh dấu xong bước [stepIndex] (tính từ 0) của [lesson].
  ///
  /// Tiến độ chỉ tăng, không giảm; xong bước cuối thì đánh dấu hoàn thành.
  /// Không dùng UPSERT (`ON CONFLICT DO UPDATE`) vì cần SQLite 3.24, trong khi
  /// Android 8 (API 26, minSdk của app) chỉ có SQLite 3.18 → đọc rồi ghi
  /// trong cùng một transaction.
  Future<LessonProgress> completeStep(
    int learnerId,
    Lesson lesson,
    int stepIndex,
  ) async {
    final db = await AppDatabase.instance;
    return db.transaction((txn) async {
      final rows = await txn.query(
        'progress',
        where: 'learner_id = ? AND lesson_id = ?',
        whereArgs: [learnerId, lesson.id],
        limit: 1,
      );
      final old = rows.isEmpty ? null : LessonProgress.fromMap(rows.first);
      final now = DateTime.now();
      final done = math
          .max(stepIndex + 1, old?.completedSteps ?? 0)
          .clamp(0, lesson.stepCount);
      final completed = done >= lesson.stepCount;
      final progress = LessonProgress(
        learnerId: learnerId,
        lessonId: lesson.id,
        completedSteps: done,
        isCompleted: completed,
        updatedAt: now,
        completedAt: completed ? (old?.completedAt ?? now) : null,
      );
      if (old == null) {
        await txn.insert('progress', progress.toMap());
      } else {
        await txn.update(
          'progress',
          progress.toMap(),
          where: 'learner_id = ? AND lesson_id = ?',
          whereArgs: [learnerId, lesson.id],
        );
      }
      return progress;
    });
  }
}
