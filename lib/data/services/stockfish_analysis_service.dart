import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../models/stockfish_analysis_model.dart';

class StockfishAnalysisService {
  final String baseUrl;

  StockfishAnalysisService({String? baseUrl})
      : baseUrl = (baseUrl ?? ApiConfig.stockfishBaseUrl).trim();

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

    if (baseUrl.isEmpty) {
      throw Exception(
        'Chưa cấu hình Stockfish API. Khi build app thật, chạy với --dart-define=STOCKFISH_BASE_URL=https://api-cua-ban.com',
      );
    }

    final uri = Uri.parse('$baseUrl/analyze/$cleanUsername').replace(
      queryParameters: {
        'max_games': maxGames.toString(),
        'depth': depth.toString(),
      },
    );

    final response = await http
        .get(
          uri,
          headers: const {'Accept': 'application/json'},
        )
        .timeout(
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
