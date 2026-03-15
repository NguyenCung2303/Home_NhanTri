import '../models/tuition_model.dart';
import '../services/database_service.dart';

class TuitionRepository {
  Future<List<TuitionModel>> getAllTuitions() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('tuitions', orderBy: 'created_at DESC');
    return result.map((e) => TuitionModel.fromMap(e)).toList();
  }

  Future<void> addTuition(TuitionModel tuition) async {
    final db = await DatabaseService.instance.database;
    await db.insert('tuitions', tuition.toMap());
  }

  Future<void> deleteTuition(String id) async {
    final db = await DatabaseService.instance.database;
    await db.delete(
      'tuitions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAsPaid(String id) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'tuitions',
      {
        'status': 'PAID',
        'paid_date': DateTime.now().toIso8601String().split('T').first,
        'payment_method': 'TRANSFER',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}