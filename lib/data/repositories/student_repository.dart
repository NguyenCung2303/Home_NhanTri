import 'package:uuid/uuid.dart';

import '../models/student_model.dart';
import '../services/database_service.dart';

class StudentRepository {
  static final _uuid = Uuid();

  Future<List<StudentModel>> getAllStudents() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('students', orderBy: 'created_at DESC');
    return result.map((e) => StudentModel.fromMap(e)).toList();
  }

  Future<List<StudentModel>> getStudentsByClass(String classId) async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery('''
      SELECT s.* FROM students s
      INNER JOIN class_student cs ON cs.student_id = s.id
      WHERE cs.class_id = ? AND cs.status = 'ACTIVE'
      ORDER BY s.full_name ASC
    ''', [classId]);
    return result.map((e) => StudentModel.fromMap(e)).toList();
  }

  Future<List<StudentModel>> getAvailableStudentsForClass(String classId) async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery('''
      SELECT s.*
      FROM students s
      WHERE s.status = 'ACTIVE'
        AND s.id NOT IN (
          SELECT cs.student_id
          FROM class_student cs
          WHERE cs.class_id = ? AND cs.status = 'ACTIVE'
        )
      ORDER BY s.full_name ASC
    ''', [classId]);
    return result.map((e) => StudentModel.fromMap(e)).toList();
  }

  /// Thêm học sinh và tự động ghi vào class_student nếu có classId
  Future<void> addStudent(StudentModel student, {String? classId}) async {
    final db = await DatabaseService.instance.database;
    await db.insert('students', student.toMap());

    if (classId != null) {
      await db.insert('class_student', {
        'id': _uuid.v4(),
        'class_id': classId,
        'student_id': student.id,
        'joined_at': DateTime.now().toIso8601String(),
        'status': 'ACTIVE',
      });

      await db.rawUpdate('''
        UPDATE class_rooms
        SET current_students = (
          SELECT COUNT(*) FROM class_student
          WHERE class_id = ? AND status = 'ACTIVE'
        )
        WHERE id = ?
      ''', [classId, classId]);
    }
  }

  Future<void> assignStudentsToClass(String classId, List<String> studentIds) async {
    if (studentIds.isEmpty) return;
    final db = await DatabaseService.instance.database;
    await db.transaction((txn) async {
      for (final studentId in studentIds) {
        final existing = await txn.query(
          'class_student',
          where: 'class_id = ? AND student_id = ? AND status = ?',
          whereArgs: [classId, studentId, 'ACTIVE'],
          limit: 1,
        );
        if (existing.isNotEmpty) continue;

        await txn.insert('class_student', {
          'id': _uuid.v4(),
          'class_id': classId,
          'student_id': studentId,
          'joined_at': DateTime.now().toIso8601String(),
          'status': 'ACTIVE',
        });
      }

      await txn.rawUpdate('''
        UPDATE class_rooms
        SET current_students = (
          SELECT COUNT(*) FROM class_student
          WHERE class_id = ? AND status = 'ACTIVE'
        )
        WHERE id = ?
      ''', [classId, classId]);
    });
  }

  Future<void> removeStudentFromClass(String classId, String studentId) async {
    final db = await DatabaseService.instance.database;
    await db.transaction((txn) async {
      await txn.update(
        'class_student',
        {'status': 'INACTIVE'},
        where: 'class_id = ? AND student_id = ? AND status = ?',
        whereArgs: [classId, studentId, 'ACTIVE'],
      );

      await txn.rawUpdate('''
        UPDATE class_rooms
        SET current_students = (
          SELECT COUNT(*) FROM class_student
          WHERE class_id = ? AND status = 'ACTIVE'
        )
        WHERE id = ?
      ''', [classId, classId]);
    });
  }

  Future<void> updateStudent(StudentModel student) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<void> deleteStudent(String id) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(
      'class_student',
      where: 'student_id = ?',
      whereArgs: [id],
    );
    await db.delete('class_student', where: 'student_id = ?', whereArgs: [id]);
    await db.delete('students', where: 'id = ?', whereArgs: [id]);

    for (final row in rows) {
      final cid = row['class_id'] as String;
      await db.rawUpdate('''
        UPDATE class_rooms
        SET current_students = (
          SELECT COUNT(*) FROM class_student
          WHERE class_id = ? AND status = 'ACTIVE'
        )
        WHERE id = ?
      ''', [cid, cid]);
    }
  }

  Future<List<StudentModel>> getStudentsByParentUserId(String userId) async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery('''
      SELECT DISTINCT s.*
      FROM students s
      INNER JOIN parent_student ps ON ps.student_id = s.id
      INNER JOIN parents p ON p.id = ps.parent_id
      WHERE p.user_id = ?
      ORDER BY s.full_name ASC
    ''', [userId]);
    return result.map((e) => StudentModel.fromMap(e)).toList();
  }

  Future<String?> getClassIdOfStudent(String studentId) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(
      'class_student',
      where: 'student_id = ? AND status = ?',
      whereArgs: [studentId, 'ACTIVE'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['class_id'] as String;
  }
}
