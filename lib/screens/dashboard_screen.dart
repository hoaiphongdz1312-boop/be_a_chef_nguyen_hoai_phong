import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models/learner.dart';
import '../data/models/lesson.dart';
import '../data/models/lesson_progress.dart';
import '../data/repositories/lesson_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../services/recommendation_service.dart';
import '../widgets/difficulty_badge.dart';
import '../widgets/lesson_card.dart';
import 'lesson_detail_screen.dart';
import 'lesson_list_screen.dart';
import 'splash_scan_screen.dart';

/// Trang riêng của học viên: lời chào, gợi ý, món đang học dở, xem tất cả.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.learner});

  final Learner learner;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  List<Lesson> _lessons = const [];
  List<LessonProgress> _progress = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lessons = await LessonRepository().getAll();
    final progress = await ProgressRepository().getForLearner(widget.learner.id);
    if (!mounted) return;
    setState(() {
      _lessons = lessons;
      _progress = progress;
      _loading = false;
    });
  }

  Future<void> _openLesson(Lesson lesson) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LessonDetailScreen(learner: widget.learner, lesson: lesson),
    ));
    _load();
  }

  Future<void> _openAll() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LessonListScreen(learner: widget.learner),
    ));
    _load();
  }

  void _switchUser() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SplashScanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byId = {for (final l in _lessons) l.id: l};
    final inProgress = _progress
        .where((p) => p.isInProgress && byId.containsKey(p.lessonId))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final completedCount = _progress.where((p) => p.isCompleted).length;
    final recommendation = RecommendationService.recommend(_lessons, _progress);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bếp của bạn'),
        actions: [
          IconButton(
            tooltip: 'Đổi người dùng',
            icon: const Icon(Icons.switch_account_outlined),
            onPressed: _switchUser,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Xin chào, ${widget.learner.name}!',
                          style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Đã hoàn thành $completedCount/${_lessons.length} món',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _SectionTitle('Gợi ý cho bạn'),
                if (recommendation != null)
                  _RecommendationCard(
                    recommendation: recommendation,
                    progress: _progress
                        .where((p) => p.lessonId == recommendation.lesson.id)
                        .firstOrNull,
                    onTap: () => _openLesson(recommendation.lesson),
                  )
                else
                  const _EmptyNote(
                    icon: Icons.emoji_events_outlined,
                    text: 'Bạn đã học hết tất cả các món. Tuyệt vời!',
                  ),
                const SizedBox(height: 8),
                _SectionTitle('Đang học dở (${inProgress.length})'),
                if (inProgress.isEmpty)
                  const _EmptyNote(
                    icon: Icons.menu_book_outlined,
                    text: 'Chưa có món nào đang học dở.',
                  )
                else
                  for (final p in inProgress)
                    LessonCard(
                      lesson: byId[p.lessonId]!,
                      progress: p,
                      onTap: () => _openLesson(byId[p.lessonId]!),
                    ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: _openAll,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.restaurant_menu),
                    label: Text('Xem tất cả món (${_lessons.length})'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color))),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.recommendation,
    required this.progress,
    required this.onTap,
  });

  final Recommendation recommendation;
  final LessonProgress? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lesson = recommendation.lesson;
    final p = progress;
    final continuing =
        recommendation.reason == RecommendationReason.continueLearning;
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome,
                      size: 18, color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      recommendation.reason.message,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  LessonIcon(difficulty: lesson.difficulty, size: 56),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lesson.name, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            DifficultyBadge(difficulty: lesson.difficulty),
                            const SizedBox(width: 8),
                            Text(formatDuration(lesson.durationMinutes),
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(lesson.description, style: theme.textTheme.bodyMedium),
              if (continuing && p != null) ...[
                const SizedBox(height: 12),
                LessonProgressBar(
                  fraction: p.fraction(lesson.stepCount),
                  color: AppTheme.difficultyColor(lesson.difficulty),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  icon: Icon(continuing ? Icons.play_arrow : Icons.restaurant),
                  label: Text(continuing
                      ? 'Học tiếp bước ${(p?.completedSteps ?? 0) + 1}'
                      : 'Bắt đầu học'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
