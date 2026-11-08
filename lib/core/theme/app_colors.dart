import 'package:flutter/material.dart';

/// Token warna dari PRD bagian 13.2.
abstract final class AppColors {
  static const Color primary = Color(0xFF6C4CE0);
  static const Color accent = Color(0xFF4A9BF5);
  static const Color navy = Color(0xFF1E1B3A);
  static const Color textSecondary = Color(0xFF5B5878);

  static const Color gradientTop = Color(0xFFCFE3FF);
  static const Color gradientBottom = Color(0xFFE8E0FF);

  // Status tekanan darah (selalu dipasangkan dengan ikon dan kata).
  static const Color bpNormal = Color(0xFFDDF5EA);
  static const Color bpElevated = Color(0xFFFFF1CC);
  static const Color bpHigh = Color(0xFFFFE0CC);
  static const Color bpVeryHigh = Color(0xFFFFD6D6);
  static const Color bpLow = Color(0xFFD6E8FF);

  static const Color danger = Color(0xFFD32F2F);
}
