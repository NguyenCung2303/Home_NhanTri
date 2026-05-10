import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/stockfish_analysis_model.dart';

class StockfishAnalysisService {
  /// Android Emulator: http://10.0.2.2:8000
  /// iOS Simulator / Desktop / Web local: http://localhost:8000
  /// Điện thoại thật: đổi thành IP LAN của máy chạy backend, ví dụ http://192.168.1.5:8000
  final String baseUrl;

  StockfishAnalysisService({this.baseUrl = 'http://localhost:8000'});

  String _normalizeUsername(String input) {
    var value = input.trim();
    value = value.replaceAll('https://lichess.org/@/', '');
    value = value.replaceAll('http://lichess.org/@/', '');
    value = value.replaceAll('lichess.org/@/', '');
    value = value.replaceAll('@/', '');
    value = value.replaceAll('@', '');
    return value.split('/').first.trim();
  }

  Future<StockfishAnalysisModel> analyzeUser(
    String username, {
    int maxGames = 5,
    int depth = 8,
  }) async {
    final cleanUsername = _normalizeUsername(username);
    if (cleanUsername.isEmpty) {
      throw Exception('Chưa có username Lichess để phân tích Stockfish');
    }

    final uri = Uri.parse('$baseUrl/analyze/$cleanUsername').replace(
      queryParameters: {
        'max_games': maxGames.toString(),
        'depth': depth.toString(),
      },
    );

    final response = await http.get(uri, headers: const {'Accept': 'application/json'}).timeout(
          const Duration(seconds: 90),
        );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Backend Stockfish trả lỗi ${response.statusCode}';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['detail'] != null) {
          message = decoded['detail'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Dữ liệu Stockfish backend không đúng định dạng');
    }

    return StockfishAnalysisModel.fromJson(decoded);
  }
}
