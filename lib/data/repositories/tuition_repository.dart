import 'package:uuid/uuid.dart';

import '../models/tuition_model.dart';
import '../services/database_service.dart';

class TuitionRepository {
  static final _uuid = Uuid();

  Future<List<TuitionModel>> getAllTuitions() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('tuitions', orderBy: 'created_at DESC');
    return result.map((e) => TuitionModel.fromMap(e)).toList();
  }

  Future<List<TuitionModel>> getTuitionsByParentUserId(String userId) async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery('''
      SELECT DISTINCT t.*
      FROM tuitions t
      INNER JOIN parent_student ps ON ps.student_id = t.student_id
      INNER JOIN parents p ON p.id = ps.parent_id
      WHERE p.user_id = ?
      ORDER BY t.created_at DESC
    ''', [userId]);
    return result.map((e) => TuitionModel.fromMap(e)).toList();
  }

  Future<void> addTuition(TuitionModel tuition) async {
    final db = await DatabaseService.instance.database;
    await db.insert('tuitions', tuition.toMap());
  }

  Future<int> generateMonthlyTuitionsForClass({
    required String classId,
    required String tuitionPeriod,
    required String dueDate,
    String? note,
  }) async {
    final db = await DatabaseService.instance.database;
    var created = 0;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      final classRows = await txn.query('class_rooms', where: 'id = ?', whereArgs: [classId], limit: 1);
      if (classRows.isEmpty) return;
      final amount = (classRows.first['tuition_fee'] as num).toDouble();

      final students = await txn.rawQuery('''
        SELECT student_id
        FROM class_student
        WHERE class_id = ? AND status = 'ACTIVE'
      ''', [classId]);

      for (final s in students) {
        final studentId = s['student_id'] as String;
        final existing = await txn.query(
          'tuitions',
          where: 'student_id = ? AND class_id = ? AND tuition_period = ?',
          whereArgs: [studentId, classId, tuitionPeriod],
          limit: 1,
        );
        if (existing.isNotEmpty) continue;

        await txn.insert('tuitions', {
          'id': _uuid.v4(),
          'student_id': studentId,
          'class_id': classId,
          'amount': amount,
          'due_date': dueDate,
          'paid_date': null,
          'status': 'UNPAID',
          'payment_method': null,
          'transaction_code': null,
          'qr_content': null,
          'note': note ?? 'Học phí kỳ $tuitionPeriod',
          'tuition_period': tuitionPeriod,
          'created_at': now,
        });
        created++;
      }
    });

    return created;
  }

  Future<void> deleteTuition(String id) async {
    final db = await DatabaseService.instance.database;
    await db.delete('tuitions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markAsPaid(String id) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'tuitions',
      {
        'status': 'PAID',
        'paid_date': DateTime.now().toIso8601String().split('T').first,
        'payment_method': 'TRANSFER',
        'transaction_code': 'GD${DateTime.now().millisecondsSinceEpoch}',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> refreshOverdueStatuses() async {
    final db = await DatabaseService.instance.database;
    final today = DateTime.now().toIso8601String().split('T').first;
    await db.update(
      'tuitions',
      {'status': 'OVERDUE'},
      where: 'status = ? AND due_date < ?',
      whereArgs: ['UNPAID', today],
    );
  }
}
