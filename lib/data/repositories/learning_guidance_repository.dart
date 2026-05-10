import 'package:uuid/uuid.dart';

import '../services/database_service.dart';

class LearningGuidanceRepository {
  static final _uuid = Uuid();

  Future<String> createGuidance({
    required String teacherId,
    required String classId,
    required String studentId,
    required String strengths,
    required String improvements,
    required String orientation,
    String status = 'DRAFT',
  }) async {
    final db = await DatabaseService.instance.database;
    final now = DateTime.now().toIso8601String();
    final id = _uuid.v4();

    await db.insert('learning_guidance', {
      'id': id,
      'teacher_id': teacherId,
      'class_id': classId,
      'student_id': studentId,
      'strengths': strengths,
      'improvements': improvements,
      'orientation': orientation,
      'status': status,
      'sent_at': status == 'SENT' ? now : null,
      'created_at': now,
    });

    return id;
  }

  Future<void> sendGuidance(String guidanceId) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'learning_guidance',
      {
        'status': 'SENT',
        'sent_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [guidanceId],
    );
  }

  Future<List<Map<String, dynamic>>> getRecentByTeacher(String teacherId) async {
    final db = await DatabaseService.instance.database;
    return db.rawQuery('''
      SELECT lg.*, s.full_name AS student_name, c.class_name
      FROM learning_guidance lg
      INNER JOIN students s ON s.id = lg.student_id
      INNER JOIN class_rooms c ON c.id = lg.class_id
      WHERE lg.teacher_id = ?
      ORDER BY lg.created_at DESC
      LIMIT 10
    ''', [teacherId]);
  }

  Future<List<Map<String, dynamic>>> getSentByParentUserId(String parentUserId) async {
    final db = await DatabaseService.instance.database;
    return db.rawQuery('''
      SELECT lg.*, s.full_name AS student_name, c.class_name, u.full_name AS teacher_name
      FROM learning_guidance lg
      INNER JOIN students s ON s.id = lg.student_id
      INNER JOIN class_rooms c ON c.id = lg.class_id
      INNER JOIN users u ON u.id = lg.teacher_id
      INNER JOIN parent_student ps ON ps.student_id = lg.student_id
      INNER JOIN parents p ON p.id = ps.parent_id
      WHERE p.user_id = ? AND lg.status = 'SENT'
      ORDER BY lg.sent_at DESC, lg.created_at DESC
    ''', [parentUserId]);
  }
}
