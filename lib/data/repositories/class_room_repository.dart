import '../models/class_room_model.dart';
import '../services/database_service.dart';

class ClassRoomRepository {
  Future<List<ClassRoomModel>> getAllClassRooms() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('class_rooms', orderBy: 'created_at DESC');
    return result.map((e) => ClassRoomModel.fromMap(e)).toList();
  }

  Future<void> addClassRoom(ClassRoomModel classRoom) async {
    final db = await DatabaseService.instance.database;
    await db.insert('class_rooms', classRoom.toMap());
  }

  Future<void> deleteClassRoom(String id) async {
    final db = await DatabaseService.instance.database;
    await db.delete(
      'class_rooms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}