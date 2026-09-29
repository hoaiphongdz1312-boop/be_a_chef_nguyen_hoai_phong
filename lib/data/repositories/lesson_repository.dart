import '../database.dart';
import '../models/lesson.dart';

class LessonRepository {
  Future<List<Lesson>> getAll() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('lessons', orderBy: 'sort_order');
    return rows.map(Lesson.fromMap).toList();
  }
}
