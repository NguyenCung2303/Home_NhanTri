import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFD4A017);
  static const Color primaryLight = Color(0xFFF2C94C);
  static const Color primaryDark = Color(0xFF9A6B00);
  static const Color primarySoft = Color(0xFFFFF6D8);

  static const Color background = Color(0xFFF8F8F6);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;

  static const Color textPrimary = Color(0xFF1C1C1C);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textMuted = Color(0xFF9A9A9A);

  static const Color border = Color(0xFFE9E3D3);

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFD32F2F);
  static const Color info = Color(0xFF3B82F6);

  // Backward-compatible aliases for old screens.
  static const Color accent = primary;
  static const Color accentSoft = primarySoft;

  static LinearGradient get goldGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF2C94C), Color(0xFFD4A017)],
      );

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.055),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  static BoxDecoration cardDecoration({double radius = 22}) {
    return BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border),
      boxShadow: softShadow,
    );
  }
}
