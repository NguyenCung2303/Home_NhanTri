class LichessProfileModel {
  final String id;
  final String username;
  final String? displayName;
  final String url;
  final int totalGames;
  final int ratedGames;
  final int win;
  final int loss;
  final int draw;
  final Map<String, int?> ratings;
  final Map<String, int?> gamesByMode;

  LichessProfileModel({
    required this.id,
    required this.username,
    this.displayName,
    required this.url,
    required this.totalGames,
    required this.ratedGames,
    required this.win,
    required this.loss,
    required this.draw,
    required this.ratings,
    required this.gamesByMode,
  });

  double get winRate => totalGames > 0 ? (win / totalGames) * 100 : 0;

  int? get bestRating {
    final values = ratings.values.whereType<int>().toList();
    if (values.isEmpty) return null;
    values.sort();
    return values.last;
  }

  String? get bestRatingMode {
    String? bestKey;
    int? bestValue;
    for (final entry in ratings.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (bestValue == null || value > bestValue) {
        bestValue = value;
        bestKey = entry.key;
      }
    }
    return bestKey;
  }

  factory LichessProfileModel.fromJson(Map<String, dynamic> json) {
    int? readPerfInt(String key, String field) {
      final perf = json['perfs']?[key];
      if (perf is Map && perf[field] is num) return (perf[field] as num).toInt();
      return null;
    }

    int readCount(String key) {
      final count = json['count'];
      if (count is Map && count[key] is num) return (count[key] as num).toInt();
      return 0;
    }

    return LichessProfileModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayName: json['profile'] is Map ? json['profile']['realName']?.toString() : null,
      url: json['url']?.toString() ?? '',
      totalGames: readCount('all'),
      ratedGames: readCount('rated'),
      win: readCount('win'),
      loss: readCount('loss'),
      draw: readCount('draw'),
      ratings: {
        'Bullet': readPerfInt('bullet', 'rating'),
        'Blitz': readPerfInt('blitz', 'rating'),
        'Rapid': readPerfInt('rapid', 'rating'),
        'Classical': readPerfInt('classical', 'rating'),
        'Puzzle': readPerfInt('puzzle', 'rating'),
      },
      gamesByMode: {
        'Bullet': readPerfInt('bullet', 'games'),
        'Blitz': readPerfInt('blitz', 'games'),
        'Rapid': readPerfInt('rapid', 'games'),
        'Classical': readPerfInt('classical', 'games'),
        'Puzzle': readPerfInt('puzzle', 'games'),
      },
    );
  }
}
