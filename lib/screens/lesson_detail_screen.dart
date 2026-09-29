import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models/learner.dart';
import '../data/models/lesson.dart';
import '../data/models/lesson_progress.dart';
import '../data/repositories/progress_repository.dart';
import '../widgets/difficulty_badge.dart';
import '../widgets/lesson_card.dart';

/// Học một món theo từng bước; tiến độ lưu riêng cho từng học viên.
///
/// Mở màn này sẽ nhảy thẳng tới bước đang dừng. Có thể xem lại bước trước,
/// nhưng chỉ bước "đang học" mới có nút "Xong bước này".
class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({
    super.key,
    required this.learner,
    required this.lesson,
  });

  final Learner learner;
  final Lesson lesson;

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final _repo = ProgressRepository();
  LessonProgress? _progress;
  bool _loading = true;
  bool _saving = false;

  /// Bước đang hiển thị (tính từ 0).
  int _viewing = 0;

  Lesson get _lesson => widget.lesson;
  int get _done => _progress?.completedSteps ?? 0;
  bool get _completed => _progress?.isCompleted ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final progress = await _repo.get(widget.learner.id, _lesson.id);
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _viewing = (progress?.completedSteps ?? 0).clamp(0, _lesson.stepCount - 1);
      _loading = false;
    });
  }

  Future<void> _completeCurrentStep() async {
    setState(() => _saving = true);
    try {
      final progress =
          await _repo.completeStep(widget.learner.id, _lesson, _viewing);
      if (!mounted) return;
      setState(() {
        _progress = progress;
        _saving = false;
        if (!progress.isCompleted) _viewing = progress.completedSteps;
      });
      if (progress.isCompleted) _showCompletedDialog();
    } catch (e) {
      debugPrint('[Lesson] lỗi lưu tiến độ: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không lưu được tiến độ, thử lại nhé.')),
      );
    }
  }

  void _showCompletedDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.emoji_events, color: AppTheme.medium, size: 40),
        title: const Text('Hoàn thành!'),
        content: Text('Bạn đã học xong món ${_lesson.name}. Chúc ngon miệng!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Xem lại'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(this.context).pop();
            },
            child: const Text('Quay lại'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_lesson.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildStep(context),
              ],
            ),
      bottomNavigationBar: _loading ? null : _buildActions(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    LessonIcon(difficulty: _lesson.difficulty, size: 40),
                    const SizedBox(width: 12),
                    DifficultyBadge(difficulty: _lesson.difficulty),
                    const SizedBox(width: 8),
                    Icon(Icons.schedule, size: 16, color: theme.colorScheme.outline),
                    const SizedBox(width: 2),
                    Text(formatDuration(_lesson.durationMinutes)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_lesson.description, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          ExpansionTile(
            leading: const Icon(Icons.shopping_basket_outlined),
            title: Text('Nguyên liệu (${_lesson.ingredients.length})'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in _lesson.ingredients)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('•  $item'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    final theme = Theme.of(context);
    final total = _lesson.stepCount;
    final stepDone = _viewing < _done;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Bước ${_viewing + 1}/$total', style: theme.textTheme.titleLarge),
            const Spacer(),
            if (_completed)
              const Chip(
                avatar: Icon(Icons.check_circle, color: AppTheme.easy),
                label: Text('Đã hoàn thành'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        LessonProgressBar(
          fraction: total == 0 ? 0 : _done / total,
          color: AppTheme.difficultyColor(_lesson.difficulty),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          color: theme.colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _lesson.steps[_viewing],
                    style: theme.textTheme.titleMedium?.copyWith(height: 1.5),
                  ),
                ),
                if (stepDone) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check, color: AppTheme.easy),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final isLast = _viewing == _lesson.stepCount - 1;
    // Chỉ bước ngay sau các bước đã xong mới được đánh dấu "Xong".
    final isFrontier = _viewing == _done && !_completed;

    final Widget primary;
    if (isFrontier) {
      primary = FilledButton.icon(
        onPressed: _saving ? null : _completeCurrentStep,
        icon: const Icon(Icons.check),
        label: Text(isLast ? 'Hoàn thành món' : 'Xong bước này'),
      );
    } else if (!isLast) {
      primary = FilledButton.tonal(
        onPressed: () => setState(() => _viewing++),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        child: const Text('Bước tiếp'),
      );
    } else {
      primary = FilledButton.tonal(
        onPressed: () => Navigator.of(context).pop(),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        child: const Text('Quay lại'),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _viewing > 0 ? () => setState(() => _viewing--) : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Bước trước'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: primary),
          ],
        ),
      ),
    );
  }
}
