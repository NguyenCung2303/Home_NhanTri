import '../models/user_model.dart';
import '../services/database_service.dart';

class AuthRepository {
  Future<UserModel?> login(String username, String password) async {
    final db = await DatabaseService.instance.database;

    final result = await db.query(
      'users',
      where: '(phone = ? OR email = ?) AND password_hash = ? AND status = ?',
      whereArgs: [username, username, password, 'ACTIVE'],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }
}