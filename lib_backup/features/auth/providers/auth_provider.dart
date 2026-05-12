import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  static const String _projectId = 'nhantri-52a8d';
  static const String _baseUrl =
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  UserModel? currentUser;
  bool isLoading = false;
  String? errorMessage;

  Future<bool> login(String username, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final input = username.trim().toLowerCase();
      final pass = password.trim();

      final users = await _getAllUsers();

      UserModel? matchedUser;

      for (final user in users) {
        final phone = user.phone?.trim().toLowerCase() ?? '';
        final email = user.email?.trim().toLowerCase() ?? '';
        final savedPassword = user.passwordHash.trim();

        if ((phone == input || email == input) && savedPassword == pass) {
          matchedUser = user;
          break;
        }
      }

      if (matchedUser == null) {
        errorMessage = 'Sai số điện thoại/email hoặc mật khẩu';
        return false;
      }

      if (matchedUser.status.toUpperCase() != 'ACTIVE') {
        errorMessage = 'Tài khoản đã bị khóa';
        return false;
      }

      currentUser = UserModel(
        id: matchedUser.id,
        fullName: matchedUser.fullName,
        phone: matchedUser.phone,
        email: matchedUser.email,
        passwordHash: matchedUser.passwordHash,
        role: matchedUser.role.toUpperCase(),
        status: matchedUser.status.toUpperCase(),
        createdAt: matchedUser.createdAt,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', currentUser!.id);
      await prefs.setString('role', currentUser!.role);
      await prefs.setString('full_name', currentUser!.fullName);
      await prefs.setString('email', currentUser!.email ?? '');
      await prefs.setString('phone', currentUser!.phone ?? '');

      return true;
    } catch (e) {
      errorMessage = 'Đăng nhập thất bại: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<UserModel>> _getAllUsers() async {
    final url = Uri.parse('$_baseUrl/users?pageSize=200');

    final response = await http.get(url).timeout(
          const Duration(seconds: 15),
        );

    if (response.statusCode == 404) return [];

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Không tải được danh sách tài khoản: ${response.body}');
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

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null || userId.isEmpty) return;

    try {
      final url = Uri.parse('$_baseUrl/users/$userId');
      final response = await http.get(url).timeout(
            const Duration(seconds: 15),
          );

      if (response.statusCode == 404) {
        await prefs.clear();
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final fields = data['fields'] as Map<String, dynamic>? ?? {};

      final user = UserModel.fromFirestore(userId, fields);

      if (user.status.toUpperCase() != 'ACTIVE') {
        await prefs.clear();
        return;
      }

      currentUser = UserModel(
        id: user.id,
        fullName: user.fullName,
        phone: user.phone,
        email: user.email,
        passwordHash: user.passwordHash,
        role: user.role.toUpperCase(),
        status: user.status.toUpperCase(),
        createdAt: user.createdAt,
      );

      notifyListeners();
    } catch (_) {
      // Không crash app khi restore session lỗi.
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    currentUser = null;
    notifyListeners();
  }
}