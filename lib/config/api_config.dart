class ApiConfig {
  static const String stockfishBaseUrl = String.fromEnvironment(
    'STOCKFISH_BASE_URL',
    defaultValue: '',
  );

  static bool get hasStockfishBaseUrl => stockfishBaseUrl.trim().isNotEmpty;
}
