import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  UserModel? currentUser;
  bool isLoading = false;
  String? errorMessage;

  Future<bool> login(String username, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.login(username, password);

      if (user == null) {
        errorMessage = 'Sai tài khoản hoặc mật khẩu';
        isLoading = false;
        notifyListeners();
        return false;
      }

      currentUser = user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.id);
      await prefs.setString('role', user.role);
      await prefs.setString('full_name', user.fullName);

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Đăng nhập thất bại: $e';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    currentUser = null;
    notifyListeners();
  }
}