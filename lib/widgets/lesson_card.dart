import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models/lesson.dart';
import '../data/models/lesson_progress.dart';
import 'difficulty_badge.dart';

/// Thẻ một món trong danh sách, kèm trạng thái học của học viên.
class LessonCard extends StatelessWidget {
  const LessonCard({
    super.key,
    required this.lesson,
    this.progress,
    required this.onTap,
  });

  final Lesson lesson;
  final LessonProgress? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = progress;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              LessonIcon(difficulty: lesson.difficulty),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        DifficultyBadge(difficulty: lesson.difficulty),
                        const SizedBox(width: 8),
                        Icon(Icons.schedule,
                            size: 14, color: theme.colorScheme.outline),
                        const SizedBox(width: 2),
                        Text(formatDuration(lesson.durationMinutes),
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                    if (p != null && p.isInProgress) ...[
                      const SizedBox(height: 8),
                      LessonProgressBar(
                        fraction: p.fraction(lesson.stepCount),
                        color: AppTheme.difficultyColor(lesson.difficulty),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusIcon(progress: p),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.progress});

  final LessonProgress? progress;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    if (p != null && p.isCompleted) {
      return const Tooltip(
        message: 'Đã hoàn thành',
        child: Icon(Icons.check_circle, color: AppTheme.easy),
      );
    }
    return Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline);
  }
}

/// Thanh tiến độ kèm phần trăm.
class LessonProgressBar extends StatelessWidget {
  const LessonProgressBar({super.key, required this.fraction, this.color});

  final double fraction;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text('${(fraction * 100).round()}%',
            style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

/// 45 → "45 phút", 90 → "1 giờ 30 phút", 240 → "4 giờ".
String formatDuration(int minutes) {
  final h = minutes ~/ 60, m = minutes % 60;
  if (h == 0) return '$m phút';
  if (m == 0) return '$h giờ';
  return '$h giờ $m phút';
}
