import '../models/schedule_model.dart';
import '../services/database_service.dart';

class ScheduleRepository {
  Future<List<ScheduleModel>> getAllSchedules() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('schedules', orderBy: 'study_date ASC');
    return result.map((e) => ScheduleModel.fromMap(e)).toList();
  }

  Future<void> addSchedule(ScheduleModel schedule) async {
    final db = await DatabaseService.instance.database;
    await db.insert('schedules', schedule.toMap());
  }

  Future<void> deleteSchedule(String id) async {
    final db = await DatabaseService.instance.database;
    await db.delete(
      'schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}