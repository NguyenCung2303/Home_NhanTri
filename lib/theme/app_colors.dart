import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF4F6FA);
  static const card = Colors.white;
  static const surface = Color(0xFFEFF3F8);
  static const accent = Color(0xFF2563EB);
  static const accentSoft = Color(0xFFEAF1FF);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
}
