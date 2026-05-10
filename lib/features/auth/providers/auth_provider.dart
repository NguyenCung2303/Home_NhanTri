import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  static const String _projectId = 'nhantri-52a8d';

  UserModel? currentUser;
  bool isLoading = false;
  String? errorMessage;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user!.uid;
      final profile = await _getUserProfile(uid);

      if (profile == null) {
        await FirebaseAuth.instance.signOut();
        errorMessage = 'Tài khoản chưa có hồ sơ người dùng';
        return false;
      }

      if (profile['isActive'] == false) {
        await FirebaseAuth.instance.signOut();
        errorMessage = 'Tài khoản đã bị khóa';
        return false;
      }

      currentUser = UserModel(
        id: uid,
        fullName: profile['fullName'] ?? '',
        phone: profile['phone'],
        email: profile['email'] ?? email,
        passwordHash: '',
        role: profile['role'] ?? '',
        status: profile['isActive'] == false ? 'INACTIVE' : 'ACTIVE',
        createdAt: DateTime.now().toIso8601String(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', currentUser!.id);
      await prefs.setString('role', currentUser!.role);
      await prefs.setString('full_name', currentUser!.fullName);
      await prefs.setString('email', currentUser!.email ?? '');

      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        errorMessage = 'Sai email hoặc mật khẩu';
      } else {
        errorMessage = 'Đăng nhập thất bại: ${e.message}';
      }
      return false;
    } catch (e) {
      errorMessage = 'Đăng nhập thất bại: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> _getUserProfile(String uid) async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/users/$uid',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode == 404) return null;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Không đọc được hồ sơ user: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final fields = json['fields'] as Map<String, dynamic>? ?? {};

    String? str(String key) => fields[key]?['stringValue']?.toString();
    bool boolVal(String key) => fields[key]?['booleanValue'] == true;

    return {
      'email': str('email'),
      'phone': str('phone'),
      'fullName': str('fullName'),
      'role': str('role'),
      'isActive': fields.containsKey('isActive') ? boolVal('isActive') : true,
    };
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    currentUser = null;
    notifyListeners();
  }
}