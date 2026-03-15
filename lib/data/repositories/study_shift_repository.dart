import '../models/study_shift_model.dart';
import '../services/database_service.dart';

class StudyShiftRepository {
  Future<List<StudyShiftModel>> getAllStudyShifts() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('study_shifts', orderBy: 'day_of_week ASC');
    return result.map((e) => StudyShiftModel.fromMap(e)).toList();
  }

  Future<void> addStudyShift(StudyShiftModel shift) async {
    final db = await DatabaseService.instance.database;
    await db.insert('study_shifts', shift.toMap());
  }

  Future<void> deleteStudyShift(String id) async {
    final db = await DatabaseService.instance.database;
    await db.delete(
      'study_shifts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}