import 'package:uuid/uuid.dart';

import '../models/student_model.dart';
import '../services/database_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;




class StudentRepository {
  static final _uuid = Uuid();

  static const String _projectId = 'nhantri-52a8d';
  static const String _baseUrl =
    'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';


  Future<List<StudentModel>> getAllStudents() async {
  final url = Uri.parse('$_baseUrl/students');

  final response = await http.get(url).timeout(const Duration(seconds: 15));

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Không tải được danh sách học sinh: ${response.body}');
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final documents = data['documents'] as List<dynamic>? ?? [];

  return documents.map((doc) {
    final document = doc as Map<String, dynamic>;
    final name = document['name']?.toString() ?? '';
    final id = name.split('/').last;
    final fields = document['fields'] as Map<String, dynamic>? ?? {};

    return StudentModel.fromFirestore(id, fields);
  }).toList();
}

  Future<List<StudentModel>> getStudentsByClass(String classId) async {
  final students = await getAllStudents();

  return students
      .where(
        (student) =>
            student.classId != null &&
            student.classId == classId,
      )
      .toList()
    ..sort((a, b) => a.fullName.compareTo(b.fullName));
}

  Future<List<StudentModel>> getAvailableStudentsForClass(String classId) async {
  final students = await getAllStudents();

  return students
      .where(
        (student) =>
            student.status == 'ACTIVE' &&
            (student.classId == null || student.classId!.isEmpty),
      )
      .toList()
    ..sort((a, b) => a.fullName.compareTo(b.fullName));
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

  Future<void> assignStudentsToClass(
  String classId,
  List<String> studentIds,
) async {
  if (studentIds.isEmpty) return;

  for (final studentId in studentIds) {
    final url = Uri.parse(
      '$_baseUrl/students/$studentId?updateMask.fieldPaths=classId',
    );

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fields': {
          'classId': {
            'stringValue': classId,
          },
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Không thể thêm học sinh vào lớp: ${response.body}',
      );
    }
  }
}

  Future<void> removeStudentFromClass(
  String classId,
  String studentId,
) async {
  final url = Uri.parse(
    '$_baseUrl/students/$studentId?updateMask.fieldPaths=classId',
  );

  final response = await http.patch(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'fields': {
        'classId': {
          'stringValue': '',
        },
      },
    }),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(
      'Không thể xóa học sinh khỏi lớp: ${response.body}',
    );
  }
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
    final students = await getAllStudents();

    final student = students.firstWhere(
      (s) => s.id == studentId,
      orElse: () => throw Exception('Không tìm thấy học sinh'),
    );

    return student.classId;
  }
}
