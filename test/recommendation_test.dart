import 'package:flutter_test/flutter_test.dart';

import 'package:nau_an_vip/data/models/lesson.dart';
import 'package:nau_an_vip/data/models/lesson_progress.dart';
import 'package:nau_an_vip/services/recommendation_service.dart';

Lesson _lesson(String id, int difficulty, int order) => Lesson(
      id: id,
      name: id,
      description: '',
      difficulty: difficulty,
      durationMinutes: 10,
      ingredients: const [],
      steps: const ['b1', 'b2', 'b3', 'b4'],
      sortOrder: order,
    );

LessonProgress _progress(String id, {int steps = 4, bool done = true, int at = 0}) =>
    LessonProgress(
      learnerId: 1,
      lessonId: id,
      completedSteps: steps,
      isCompleted: done,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(at),
    );

void main() {
  // Thứ tự trong file cố ý không theo độ khó để kiểm tra việc sắp xếp.
  final lessons = [
    _lesson('vua1', 2, 0),
    _lesson('de1', 1, 1),
    _lesson('de2', 1, 2),
    _lesson('kho1', 3, 3),
    _lesson('vua2', 2, 4),
  ];

  String? pick(List<LessonProgress> p) =>
      RecommendationService.recommend(lessons, p)?.lesson.id;
  RecommendationReason? why(List<LessonProgress> p) =>
      RecommendationService.recommend(lessons, p)?.reason;

  test('người mới → món dễ nhất (hòa thì theo thứ tự)', () {
    expect(pick([]), 'de1');
    expect(why([]), RecommendationReason.beginner);
  });

  test('ưu tiên món đang học dở cập nhật gần nhất', () {
    final p = [
      _progress('de1'),
      _progress('vua1', steps: 1, done: false, at: 100),
      _progress('kho1', steps: 2, done: false, at: 200),
    ];
    expect(pick(p), 'kho1');
    expect(why(p), RecommendationReason.continueLearning);
  });

  test('không có món dở → cùng độ khó cao nhất đã hoàn thành', () {
    final p = [_progress('de1')];
    expect(pick(p), 'de2');
    expect(why(p), RecommendationReason.sameLevel);
  });

  test('hết món cùng mức → khó hơn một bậc', () {
    final p = [_progress('de1'), _progress('de2')];
    expect(pick(p), 'vua1');
    expect(why(p), RecommendationReason.nextLevel);
  });

  test('lấy độ khó CAO NHẤT đã hoàn thành làm mốc', () {
    // Đã xong một món vừa (2) dù còn món dễ chưa học → gợi ý món vừa khác.
    final p = [_progress('de1'), _progress('vua1')];
    expect(pick(p), 'vua2');
  });

  test('không còn món ở mức D và D+1 → món chưa học dễ nhất còn lại', () {
    final p = [_progress('kho1')];
    expect(pick(p), 'de1');
    expect(why(p), RecommendationReason.remaining);
  });

  test('đã học hết → null', () {
    final p = [for (final l in lessons) _progress(l.id)];
    expect(RecommendationService.recommend(lessons, p), isNull);
  });

  test('tiến độ 0 bước chưa hoàn thành được coi là chưa học', () {
    final p = [_progress('de1', steps: 0, done: false, at: 999)];
    expect(pick(p), 'de1');
    expect(why(p), RecommendationReason.beginner);
  });

  test('bỏ qua tiến độ của món không còn tồn tại', () {
    final p = [_progress('mon-da-xoa', steps: 2, done: false, at: 999)];
    expect(pick(p), 'de1');
  });

  test('không có bài học nào → null', () {
    expect(RecommendationService.recommend([], []), isNull);
  });
}
