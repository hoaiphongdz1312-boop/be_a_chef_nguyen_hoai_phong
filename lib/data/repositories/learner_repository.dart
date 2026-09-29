import 'dart:typed_data';

import '../database.dart';
import '../models/learner.dart';

class LearnerRepository {
  Future<List<Learner>> getAll() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('learners', orderBy: 'name COLLATE NOCASE');
    return rows.map(Learner.fromMap).toList();
  }

  Future<Learner> insert({
    required String name,
    required Float32List embedding,
    required int sampleCount,
  }) async {
    final db = await AppDatabase.instance;
    final now = DateTime.now();
    final id = await db.insert('learners', {
      'name': name,
      'embedding': embedding.buffer.asUint8List(
        embedding.offsetInBytes,
        embedding.lengthInBytes,
      ),
      'embedding_dim': embedding.length,
      'sample_count': sampleCount,
      'created_at': now.millisecondsSinceEpoch,
    });
    return Learner(
      id: id,
      name: name,
      embedding: embedding,
      sampleCount: sampleCount,
      createdAt: now,
    );
  }
}
