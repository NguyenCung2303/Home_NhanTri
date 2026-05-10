class StockfishIssueModel {
  final String type;
  final String phase;
  final int moveNumber;
  final String playedMove;
  final double evalBefore;
  final double evalAfter;
  final double drop;
  final String? gameUrl;
  final String? opening;

  StockfishIssueModel({
    required this.type,
    required this.phase,
    required this.moveNumber,
    required this.playedMove,
    required this.evalBefore,
    required this.evalAfter,
    required this.drop,
    this.gameUrl,
    this.opening,
  });

  factory StockfishIssueModel.fromJson(Map<String, dynamic> json) {
    return StockfishIssueModel(
      type: json['type']?.toString() ?? '',
      phase: json['phase']?.toString() ?? '',
      moveNumber: (json['moveNumber'] as num?)?.toInt() ?? 0,
      playedMove: json['playedMove']?.toString() ?? '',
      evalBefore: (json['evalBefore'] as num?)?.toDouble() ?? 0,
      evalAfter: (json['evalAfter'] as num?)?.toDouble() ?? 0,
      drop: (json['drop'] as num?)?.toDouble() ?? 0,
      gameUrl: json['gameUrl']?.toString(),
      opening: json['opening']?.toString(),
    );
  }
}

class StockfishAnalysisModel {
  final String username;
  final bool engineAvailable;
  final String? engineError;
  final int gamesFetched;
  final int gamesAnalyzed;
  final String suggestion;
  final Map<String, dynamic> stats;
  final List<StockfishIssueModel> topIssues;

  StockfishAnalysisModel({
    required this.username,
    required this.engineAvailable,
    this.engineError,
    required this.gamesFetched,
    required this.gamesAnalyzed,
    required this.suggestion,
    required this.stats,
    required this.topIssues,
  });

  factory StockfishAnalysisModel.fromJson(Map<String, dynamic> json) {
    final issuesRaw = json['topIssues'];
    return StockfishAnalysisModel(
      username: json['username']?.toString() ?? '',
      engineAvailable: json['engineAvailable'] == true,
      engineError: json['engineError']?.toString(),
      gamesFetched: (json['gamesFetched'] as num?)?.toInt() ?? 0,
      gamesAnalyzed: (json['gamesAnalyzed'] as num?)?.toInt() ?? 0,
      suggestion: json['suggestion']?.toString() ?? '',
      stats: json['stats'] is Map ? Map<String, dynamic>.from(json['stats'] as Map) : const {},
      topIssues: issuesRaw is List
          ? issuesRaw
              .whereType<Map>()
              .map((e) => StockfishIssueModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  int statInt(String key) => (stats[key] as num?)?.toInt() ?? 0;
  double statDouble(String key) => (stats[key] as num?)?.toDouble() ?? 0;
}
