import 'package:flutter/material.dart';

/// Màu và theme dùng chung cho toàn app (Material 3).
abstract final class AppTheme {
  /// Màu gốc: cam đất, gợi cảm giác bếp núc.
  static const Color seed = Color(0xFFD9480F);

  /// Màu theo độ khó món ăn (1 = dễ, 2 = vừa, 3 = khó).
  static const Color easy = Color(0xFF2F9E44);
  static const Color medium = Color(0xFFF08C00);
  static const Color hard = Color(0xFFC92A2A);

  static Color difficultyColor(int difficulty) => switch (difficulty) {
        <= 1 => easy,
        2 => medium,
        _ => hard,
      };

  static String difficultyLabel(int difficulty) => switch (difficulty) {
        <= 1 => 'Dễ',
        2 => 'Vừa',
        _ => 'Khó',
      };

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: seed);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
