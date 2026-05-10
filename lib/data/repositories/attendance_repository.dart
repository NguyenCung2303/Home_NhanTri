import 'package:uuid/uuid.dart';

import '../models/attendance_record_model.dart';
import '../models/student_model.dart';
import '../models/student_tag_model.dart';
import '../services/database_service.dart';

class AttendanceSummary {
  final int presentCount;
  final int absentCount;

  const AttendanceSummary({
    required this.presentCount,
    required this.absentCount,
  });

  int get totalSessions => presentCount + absentCount;
}

class AttendanceRepository {
  static final _uuid = Uuid();

  Future<List<StudentModel>> getStudentsForClass(String classId) async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery('''
      SELECT s.*
      FROM students s
      INNER JOIN class_student cs ON cs.student_id = s.id
      WHERE cs.class_id = ? AND cs.status = 'ACTIVE' AND s.status = 'ACTIVE'
      ORDER BY s.full_name ASC
    ''', [classId]);

    return result.map(StudentModel.fromMap).toList();
  }


  Future<List<StudentTagModel>> getActiveStudentTags() async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery('''
      SELECT
        t.*,
        COUNT(CASE WHEN sta.status = 'ACTIVE' THEN sta.student_id END) AS student_count
      FROM student_tags t
      LEFT JOIN student_tag_assignments sta ON sta.tag_id = t.id
      WHERE t.status = 'ACTIVE'
      GROUP BY t.id
      ORDER BY t.sort_order ASC, t.tag_name ASC
    ''');

    return result.map(StudentTagModel.fromMap).toList();
  }

  Future<List<StudentModel>> getStudentsForTag(String tagId) async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery('''
      SELECT s.*
      FROM students s
      INNER JOIN student_tag_assignments sta ON sta.student_id = s.id
      WHERE sta.tag_id = ? AND sta.status = 'ACTIVE' AND s.status = 'ACTIVE'
      ORDER BY s.full_name ASC
    ''', [tagId]);

    return result.map(StudentModel.fromMap).toList();
  }

  Future<List<AttendanceRecordModel>> getAttendanceForTagOnDate({
    required String tagId,
    required String attendanceDate,
  }) async {
    final db = await DatabaseService.instance.database;
    final groupClassId = 'TAG_$tagId';
    final result = await db.query(
      'attendance_records',
      where: 'class_id = ? AND attendance_date = ?',
      whereArgs: [groupClassId, attendanceDate],
      orderBy: 'created_at ASC',
    );

    return result.map(AttendanceRecordModel.fromMap).toList();
  }

  Future<void> saveTagAttendance({
    required String tagId,
    required String attendanceDate,
    required Map<String, bool> studentPresentMap,
  }) async {
    await saveAttendance(
      classId: 'TAG_$tagId',
      attendanceDate: attendanceDate,
      studentPresentMap: studentPresentMap,
      scheduleId: 'TAG_${tagId}_$attendanceDate',
    );
  }


  Future<List<AttendanceRecordModel>> getAttendanceForGroupInMonth({
    required String classId,
    required int year,
    required int month,
  }) async {
    final db = await DatabaseService.instance.database;
    final monthText = month.toString().padLeft(2, '0');
    final prefix = '$year-$monthText';
    final result = await db.query(
      'attendance_records',
      where: 'class_id = ? AND attendance_date LIKE ?',
      whereArgs: [classId, '$prefix%'],
      orderBy: 'attendance_date ASC, created_at ASC',
    );

    return result.map(AttendanceRecordModel.fromMap).toList();
  }

  Future<List<AttendanceRecordModel>> getAttendanceForClassOnDate({
    required String classId,
    required String attendanceDate,
  }) async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(
      'attendance_records',
      where: 'class_id = ? AND attendance_date = ?',
      whereArgs: [classId, attendanceDate],
      orderBy: 'created_at ASC',
    );

    return result.map(AttendanceRecordModel.fromMap).toList();
  }

  Future<void> saveAttendance({
    required String classId,
    required String attendanceDate,
    required Map<String, bool> studentPresentMap,
    String? scheduleId,
  }) async {
    final db = await DatabaseService.instance.database;
    final now = DateTime.now().toIso8601String();
    final effectiveScheduleId = scheduleId ?? '${classId}_$attendanceDate';

    await db.transaction((txn) async {
      for (final entry in studentPresentMap.entries) {
        final existing = await txn.query(
          'attendance_records',
          where: 'class_id = ? AND student_id = ? AND attendance_date = ?',
          whereArgs: [classId, entry.key, attendanceDate],
          limit: 1,
        );

        final payload = {
          'schedule_id': effectiveScheduleId,
          'class_id': classId,
          'student_id': entry.key,
          'attendance_date': attendanceDate,
          'status': entry.value ? 'PRESENT' : 'ABSENT',
          'updated_at': now,
        };

        if (existing.isEmpty) {
          await txn.insert('attendance_records', {
            'id': _uuid.v4(),
            ...payload,
            'note': null,
            'created_at': now,
          });
        } else {
          await txn.update(
            'attendance_records',
            payload,
            where: 'id = ?',
            whereArgs: [existing.first['id']],
          );
        }
      }
    });
  }

  Future<List<AttendanceRecordModel>> getAttendanceByParentUserId(String userId) async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery('''
      SELECT ar.*
      FROM attendance_records ar
      INNER JOIN parent_student ps ON ps.student_id = ar.student_id
      INNER JOIN parents p ON p.id = ps.parent_id
      WHERE p.user_id = ?
      ORDER BY ar.attendance_date DESC, ar.created_at DESC
    ''', [userId]);

    return result.map(AttendanceRecordModel.fromMap).toList();
  }

  Future<AttendanceSummary> getAttendanceSummaryByParentUserId(String userId) async {
    final records = await getAttendanceByParentUserId(userId);
    final present = records.where((e) => e.status == 'PRESENT').length;
    final absent = records.where((e) => e.status == 'ABSENT').length;

    return AttendanceSummary(presentCount: present, absentCount: absent);
  }
}
