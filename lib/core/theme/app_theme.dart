import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema terang sesuai PRD 13.2. Font Poppins dibundel di assets/fonts
/// (tidak butuh internet). Mode gelap bersifat opsional (FR-802).
abstract final class AppTheme {
  static const String fontFamily = 'Poppins';

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.navy,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
    );
    final t = base.textTheme.apply(
      fontFamily: fontFamily,
      bodyColor: AppColors.navy,
      displayColor: AppColors.navy,
    );
    final text = t.copyWith(
      // Ukuran minimal isi 16 (NFR-03).
      bodyLarge: t.bodyLarge?.copyWith(fontSize: 16),
      bodyMedium: t.bodyMedium?.copyWith(fontSize: 16),
      bodySmall: t.bodySmall?.copyWith(fontSize: 14),
      titleMedium: t.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: t.headlineSmall?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
    );

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: AppColors.gradientBottom,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          side: const BorderSide(color: AppColors.primary),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
      ),
    );
  }
}
