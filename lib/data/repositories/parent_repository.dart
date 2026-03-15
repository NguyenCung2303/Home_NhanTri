import '../models/parent_model.dart';
import '../services/database_service.dart';

class ParentRepository {
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
    await db.delete(
      'parents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}