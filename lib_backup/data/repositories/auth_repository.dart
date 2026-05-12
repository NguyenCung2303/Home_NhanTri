import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user_model.dart';

class AuthRepository {
  static const String _projectId = 'nhantri-52a8d';
  static const String _baseUrl =
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  Future<UserModel?> login(String username, String password) async {
    final users = await _getUsers();
    final key = username.trim().toLowerCase();

    for (final user in users) {
      final phone = user.phone?.trim().toLowerCase() ?? '';
      final email = user.email?.trim().toLowerCase() ?? '';
      if ((phone == key || email == key) &&
          user.passwordHash == password.trim() &&
          user.status == 'ACTIVE') {
        return user;
      }
    }

    return null;
  }

  Future<List<UserModel>> _getUsers() async {
    final url = Uri.parse('$_baseUrl/users?pageSize=200');
    final response = await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode == 404) return [];
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Không tải được danh sách user: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = data['documents'] as List<dynamic>? ?? [];

    return documents.map((doc) {
      final document = doc as Map<String, dynamic>;
      final name = document['name']?.toString() ?? '';
      final id = name.split('/').last;
      final fields = document['fields'] as Map<String, dynamic>? ?? {};
      return UserModel.fromFirestore(id, fields);
    }).toList();
  }
}
