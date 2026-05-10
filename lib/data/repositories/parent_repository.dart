import 'package:uuid/uuid.dart';

import '../models/parent_model.dart';
import '../models/student_model.dart';
import '../services/database_service.dart';

class ParentRepository {
  static final _uuid = Uuid();

  Future<List<ParentModel>> getAllParents() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('parents', orderBy: 'created_at DESC');
    return result.map((e) => ParentModel.fromMap(e)).toList();
  }

  Future<void> addParent(ParentModel parent) async {
    final db = await DatabaseService.instance.database;
    await db.insert('parents', parent.toMap());
  }

  Future<void> deleteParent(String id) async {
    final db = await DatabaseService.instance.database;
    await db.transaction((txn) async {
      await txn.delete(
        'parent_student',
        where: 'parent_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'parents',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<List<StudentModel>> getStudentsByParent(String parentId) async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery('''
      SELECT s.*
      FROM students s
      INNER JOIN parent_student ps ON ps.student_id = s.id
      WHERE ps.parent_id = ? AND s.status = 'ACTIVE'
      ORDER BY s.full_name ASC
    ''', [parentId]);
    return result.map((e) => StudentModel.fromMap(e)).toList();
  }

  Future<List<StudentModel>> getAvailableStudentsForParent(String parentId) async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery('''
      SELECT s.*
      FROM students s
      WHERE s.status = 'ACTIVE'
        AND s.id NOT IN (
          SELECT ps.student_id
          FROM parent_student ps
          WHERE ps.parent_id = ?
        )
      ORDER BY s.full_name ASC
    ''', [parentId]);
    return result.map((e) => StudentModel.fromMap(e)).toList();
  }

  Future<void> assignStudentsToParent(String parentId, List<String> studentIds) async {
    if (studentIds.isEmpty) return;
    final db = await DatabaseService.instance.database;
    await db.transaction((txn) async {
      for (final studentId in studentIds) {
        final existing = await txn.query(
          'parent_student',
          where: 'parent_id = ? AND student_id = ?',
          whereArgs: [parentId, studentId],
          limit: 1,
        );
        if (existing.isNotEmpty) continue;

        await txn.insert('parent_student', {
          'id': _uuid.v4(),
          'parent_id': parentId,
          'student_id': studentId,
          'is_primary_contact': 1,
        });
      }
    });
  }

  Future<void> removeStudentFromParent(String parentId, String studentId) async {
    final db = await DatabaseService.instance.database;
    await db.delete(
      'parent_student',
      where: 'parent_id = ? AND student_id = ?',
      whereArgs: [parentId, studentId],
    );
  }
}
