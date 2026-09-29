import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:nau_an_vip/data/models/lesson.dart';

/// Kiểm tra dữ liệu mẫu assets/data/lessons.json hợp lệ trước khi seed vào DB.
void main() {
  final lessons =
      Lesson.listFromJson(File('assets/data/lessons.json').readAsStringSync());

  test('có 8–10 món', () {
    expect(lessons.length, inInclusiveRange(8, 10));
  });

  test('id không trùng', () {
    expect(lessons.map((l) => l.id).toSet().length, lessons.length);
  });

  test('mỗi món có đủ thông tin hợp lệ', () {
    for (final l in lessons) {
      expect(l.name.trim(), isNotEmpty, reason: l.id);
      expect(l.description.trim(), isNotEmpty, reason: l.id);
      expect(l.difficulty, inInclusiveRange(1, 3), reason: l.id);
      expect(l.durationMinutes, greaterThan(0), reason: l.id);
      expect(l.ingredients, isNotEmpty, reason: l.id);
      expect(l.steps.length, greaterThanOrEqualTo(3), reason: l.id);
    }
  });

  test('có món ở cả 3 mức độ khó', () {
    expect(lessons.map((l) => l.difficulty).toSet(), {1, 2, 3});
  });

  test('toMap/fromMap giữ nguyên dữ liệu', () {
    final l = lessons.first;
    final back = Lesson.fromMap(l.toMap());
    expect(back.id, l.id);
    expect(back.steps, l.steps);
    expect(back.ingredients, l.ingredients);
    expect(back.sortOrder, l.sortOrder);
  });
}
