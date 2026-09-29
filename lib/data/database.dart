import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../core/config.dart';
import 'models/lesson.dart';

/// Mở (và tạo nếu chưa có) cơ sở dữ liệu SQLite của app.
///
/// Lịch sử phiên bản:
/// - v1: bảng learners.
/// - v2: thêm lessons và progress.
abstract final class AppDatabase {
  static const int _version = 2;
  static Future<Database>? _db;

  static Future<Database> get instance => _db ??= _open();

  static Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      p.join(dir, AppConfig.databaseName),
      version: _version,
      // Bật khóa ngoại để ON DELETE CASCADE hoạt động.
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await _createLearners(db);
        await _createLessonsAndProgress(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createLessonsAndProgress(db);
      },
    );
    await _seedLessonsIfEmpty(db);
    return db;
  }

  static Future<void> _createLearners(Database db) => db.execute('''
    CREATE TABLE learners (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      embedding BLOB NOT NULL,
      embedding_dim INTEGER NOT NULL,
      sample_count INTEGER NOT NULL,
      created_at INTEGER NOT NULL
    )
  ''');

  static Future<void> _createLessonsAndProgress(Database db) async {
    await db.execute('''
      CREATE TABLE lessons (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        difficulty INTEGER NOT NULL CHECK (difficulty BETWEEN 1 AND 3),
        duration_minutes INTEGER NOT NULL,
        ingredients TEXT NOT NULL,
        steps TEXT NOT NULL,
        sort_order INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE progress (
        learner_id INTEGER NOT NULL REFERENCES learners(id) ON DELETE CASCADE,
        lesson_id TEXT NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
        completed_steps INTEGER NOT NULL DEFAULT 0,
        is_completed INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL,
        completed_at INTEGER,
        PRIMARY KEY (learner_id, lesson_id)
      )
    ''');
  }

  /// Nạp dữ liệu mẫu từ assets/data/lessons.json khi bảng lessons còn trống
  /// (lần chạy đầu tiên).
  static Future<void> _seedLessonsIfEmpty(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM lessons'),
    );
    if (count != null && count > 0) return;
    final lessons = Lesson.listFromJson(
      await rootBundle.loadString(AppConfig.lessonsAsset),
    );
    final batch = db.batch();
    for (final lesson in lessons) {
      batch.insert('lessons', lesson.toMap());
    }
    await batch.commit(noResult: true);
  }
}
