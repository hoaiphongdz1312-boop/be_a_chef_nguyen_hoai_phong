import 'package:flutter_test/flutter_test.dart';

import 'package:nau_an_vip/core/theme.dart';

void main() {
  test('màu và nhãn theo độ khó', () {
    expect(AppTheme.difficultyLabel(1), 'Dễ');
    expect(AppTheme.difficultyLabel(2), 'Vừa');
    expect(AppTheme.difficultyLabel(3), 'Khó');
    expect(AppTheme.difficultyColor(1), AppTheme.easy);
    expect(AppTheme.difficultyColor(3), AppTheme.hard);
  });

  test('theme dùng Material 3', () {
    expect(AppTheme.light().useMaterial3, isTrue);
  });
}
