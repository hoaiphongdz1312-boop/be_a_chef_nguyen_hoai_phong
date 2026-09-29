import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models/learner.dart';
import '../data/models/lesson.dart';
import '../data/models/lesson_progress.dart';
import '../data/repositories/lesson_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../widgets/lesson_card.dart';
import 'lesson_detail_screen.dart';

/// Tất cả các món, lọc theo độ khó, kèm trạng thái học của học viên.
class LessonListScreen extends StatefulWidget {
  const LessonListScreen({super.key, required this.learner});

  final Learner learner;

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  List<Lesson>? _lessons;
  Map<String, LessonProgress> _progress = const {};

  /// `null` = tất cả độ khó.
  int? _difficulty;

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
      _progress = {for (final p in progress) p.lessonId: p};
    });
  }

  Future<void> _open(Lesson lesson) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LessonDetailScreen(learner: widget.learner, lesson: lesson),
    ));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final lessons = _lessons;
    final shown = lessons
        ?.where((l) => _difficulty == null || l.difficulty == _difficulty)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Tất cả món')),
      body: lessons == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      for (final level in <int?>[null, 1, 2, 3])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(level == null
                                ? 'Tất cả'
                                : AppTheme.difficultyLabel(level)),
                            selected: _difficulty == level,
                            onSelected: (_) => setState(() => _difficulty = level),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: shown!.isEmpty
                      ? const Center(child: Text('Không có món nào ở mức này.'))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: shown.length,
                          itemBuilder: (context, i) => LessonCard(
                            lesson: shown[i],
                            progress: _progress[shown[i].id],
                            onTap: () => _open(shown[i]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
