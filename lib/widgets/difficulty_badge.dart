import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Nhãn độ khó: số ngọn lửa + chữ, tô màu theo độ khó.
class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({super.key, required this.difficulty});

  final int difficulty;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.difficultyColor(difficulty);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < difficulty.clamp(1, 3); i++)
            Icon(Icons.local_fire_department, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            AppTheme.difficultyLabel(difficulty),
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Biểu tượng món theo độ khó (không dùng ảnh có bản quyền).
class LessonIcon extends StatelessWidget {
  const LessonIcon({super.key, required this.difficulty, this.size = 48});

  final int difficulty;
  final double size;

  static IconData iconFor(int difficulty) => switch (difficulty) {
        <= 1 => Icons.egg_alt_outlined,
        2 => Icons.soup_kitchen_outlined,
        _ => Icons.ramen_dining_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.difficultyColor(difficulty);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Icon(iconFor(difficulty), color: color, size: size * 0.55),
    );
  }
}
