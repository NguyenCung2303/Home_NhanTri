import '../models/class_room_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class ClassRoomRepository {
  Future<List<ClassRoomModel>> getAllClassRooms() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('class_rooms', orderBy: 'created_at DESC');
    return result.map((e) => ClassRoomModel.fromMap(e)).toList();
  }

  Future<List<ClassRoomModel>> getClassRoomsForTeacher(String teacherId) async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery('''
      SELECT c.*
      FROM class_rooms c
      INNER JOIN class_teacher_assignments a ON a.class_id = c.id
      WHERE a.teacher_id = ? AND a.status = 'ACTIVE'
      ORDER BY c.created_at DESC
    ''', [teacherId]);
    return result.map((e) => ClassRoomModel.fromMap(e)).toList();
  }

  Future<ClassRoomModel?> getClassRoomById(String id) async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(
      'class_rooms',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return ClassRoomModel.fromMap(result.first);
  }

  Future<List<UserModel>> getTeachers() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(
      'users',
      where: 'role = ? AND status = ?',
      whereArgs: ['TEACHER', 'ACTIVE'],
      orderBy: 'full_name ASC',
    );
    return result.map((e) => UserModel.fromMap(e)).toList();
  }

  Future<String?> getAssignedTeacherId(String classId) async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(
      'class_teacher_assignments',
      columns: ['teacher_id'],
      where: 'class_id = ? AND status = ?',
      whereArgs: [classId, 'ACTIVE'],
      orderBy: 'assigned_at DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['teacher_id'] as String?;
  }

  Future<void> addClassRoom(ClassRoomModel classRoom, {String? teacherId}) async {
    final db = await DatabaseService.instance.database;
    await db.transaction((txn) async {
      await txn.insert('class_rooms', classRoom.toMap());
      if (teacherId != null && teacherId.trim().isNotEmpty) {
        await txn.insert('class_teacher_assignments', {
          'id': '${classRoom.id}_$teacherId',
          'class_id': classRoom.id,
          'teacher_id': teacherId,
          'assigned_at': DateTime.now().toIso8601String(),
          'status': 'ACTIVE',
        });
      }
    });
  }

  Future<void> updateClassRoom(ClassRoomModel classRoom, {String? teacherId}) async {
    final db = await DatabaseService.instance.database;
    await db.transaction((txn) async {
      await txn.update(
        'class_rooms',
        classRoom.toMap(),
        where: 'id = ?',
        whereArgs: [classRoom.id],
      );

      await txn.update(
        'class_teacher_assignments',
        {'status': 'INACTIVE'},
        where: 'class_id = ? AND status = ?',
        whereArgs: [classRoom.id, 'ACTIVE'],
      );

      if (teacherId != null && teacherId.trim().isNotEmpty) {
        await txn.insert('class_teacher_assignments', {
          'id': '${classRoom.id}_${teacherId}_${DateTime.now().millisecondsSinceEpoch}',
          'class_id': classRoom.id,
          'teacher_id': teacherId,
          'assigned_at': DateTime.now().toIso8601String(),
          'status': 'ACTIVE',
        });
      }
    });
  }

  Future<void> deleteClassRoom(String id) async {
    final db = await DatabaseService.instance.database;
    await db.transaction((txn) async {
      await txn.delete('class_teacher_assignments', where: 'class_id = ?', whereArgs: [id]);
      await txn.delete('class_rooms', where: 'id = ?', whereArgs: [id]);
    });
  }
}
