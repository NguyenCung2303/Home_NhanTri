import '../models/student_model.dart';
import '../services/database_service.dart';

class StudentRepository {
  Future<List<StudentModel>> getAllStudents() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('students', orderBy: 'created_at DESC');
    return result.map((e) => StudentModel.fromMap(e)).toList();
  }

  Future<void> addStudent(StudentModel student) async {
    final db = await DatabaseService.instance.database;
    await db.insert('students', student.toMap());
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
    await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}