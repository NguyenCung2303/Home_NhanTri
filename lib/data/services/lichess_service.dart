import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/lichess_profile_model.dart';

class LichessService {
  String _normalizeUsername(String input) {
    var value = input.trim();
    if (value.isEmpty) return value;

    // Cho phép admin nhập NguyenCung, @/NguyenCung hoặc cả link https://lichess.org/@/NguyenCung.
    value = value.replaceAll('https://lichess.org/@/', '');
    value = value.replaceAll('http://lichess.org/@/', '');
    value = value.replaceAll('lichess.org/@/', '');
    value = value.replaceAll('@/', '');
    value = value.replaceAll('@', '');
    value = value.split('/').first.trim();
    return value;
  }

  Future<LichessProfileModel> fetchProfile(String username) async {
    final cleanUsername = _normalizeUsername(username);
    if (cleanUsername.isEmpty) {
      throw Exception('Chưa có username Lichess');
    }

    final uri = Uri.https('lichess.org', '/api/user/$cleanUsername');
    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'HomeNhanTriChessCenter/1.0',
      },
    );

    if (response.statusCode == 404) {
      throw Exception('Không tìm thấy tài khoản Lichess: $cleanUsername');
    }
    if (response.statusCode == 429) {
      throw Exception('Lichess đang giới hạn tần suất gọi API. Thử lại sau ít phút.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Lichess trả lỗi ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Dữ liệu Lichess không đúng định dạng JSON mong đợi');
    }

    return LichessProfileModel.fromJson(decoded);
  }
}
