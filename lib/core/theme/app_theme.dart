import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static const String fontFamily = 'Poppins';

  static ThemeData light() {
    const navy = AppColors.navy;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: navy,
      onSurfaceVariant: AppColors.textSecondary,
      outline: const Color(0xFFB7B3C8),
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: AppColors.gradientBottom,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: navy,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        indicatorColor: AppColors.primary.withValues(alpha: 0.14),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.primary.withValues(alpha: 0.08);
          }
          return Colors.transparent;
        }),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(
            color: navy,
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const WidgetStatePropertyAll(
          IconThemeData(color: AppColors.textSecondary),
        ),
      ),
      inputDecorationTheme: _inputTheme(
        fill: Colors.white,
        text: navy,
        hint: AppColors.textSecondary,
        border: const Color(0xFFB7B3C8),
        focus: AppColors.primary,
      ),
    );
  }

  static ThemeData dark() {
    const background = Color(0xFF111426);
    const surface = Color(0xFF1C2038);
    const surfaceHigh = Color(0xFF282D4A);
    const text = Color(0xFFF5F3FF);
    const secondary = Color(0xFFC5C4D8);
    const primary = Color(0xFFB4A2FF);
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: background,
      surface: surface,
      onSurface: text,
      surfaceContainer: surfaceHigh,
      onSurfaceVariant: secondary,
      outline: const Color(0xFF777B9A),
      error: const Color(0xFFFF9B9B),
      onError: background,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: background,
      cardColor: surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF3B4164)),
      dialogTheme: const DialogThemeData(
        backgroundColor: surface,
        titleTextStyle: TextStyle(
          color: text,
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: secondary,
          fontFamily: fontFamily,
          fontSize: 16,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.24),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return primary.withValues(alpha: 0.10);
          }
          return Colors.transparent;
        }),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(
            color: text,
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const WidgetStatePropertyAll(
          IconThemeData(color: secondary),
        ),
      ),
      inputDecorationTheme: _inputTheme(
        fill: surfaceHigh,
        text: text,
        hint: secondary,
        border: const Color(0xFF777B9A),
        focus: primary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceHigh,
        selectedColor: primary.withValues(alpha: 0.24),
        labelStyle: const TextStyle(color: text, fontFamily: fontFamily),
        secondaryLabelStyle: const TextStyle(
          color: text,
          fontFamily: fontFamily,
        ),
        side: const BorderSide(color: Color(0xFF777B9A)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      brightness: scheme.brightness,
    );
    final text = base.textTheme
        .apply(
          fontFamily: fontFamily,
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        )
        .copyWith(
          bodyLarge: base.textTheme.bodyLarge?.copyWith(
            fontSize: 16,
            color: scheme.onSurface,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            fontSize: 16,
            color: scheme.onSurface,
          ),
          bodySmall: base.textTheme.bodySmall?.copyWith(
            fontSize: 14,
            color: scheme.onSurfaceVariant,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        );
    return base.copyWith(
      textTheme: text,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      hoverColor: scheme.primary.withValues(alpha: 0.05),
      focusColor: scheme.primary.withValues(alpha: 0.10),
      highlightColor: scheme.primary.withValues(alpha: 0.06),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: Colors.transparent,
        selectedTileColor: scheme.primary.withValues(alpha: 0.10),
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontFamily: fontFamily,
        ),
        subtitleTextStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontFamily: fontFamily,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return scheme.primary.withValues(alpha: 0.10);
            }
            return Colors.transparent;
          }),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          overlayColor: scheme.onPrimary.withValues(alpha: 0.12),
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
          side: BorderSide(color: scheme.primary),
          foregroundColor: scheme.primary,
          overlayColor: scheme.primary.withValues(alpha: 0.10),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: scheme.onInverseSurface,
          fontSize: 16,
        ),
      ),
    );
  }

  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color text,
    required Color hint,
    required Color border,
    required Color focus,
  }) {
    OutlineInputBorder makeBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      labelStyle: TextStyle(color: hint, fontSize: 15),
      hintStyle: TextStyle(color: hint, fontSize: 15),
      helperStyle: TextStyle(color: hint, fontSize: 14),
      errorStyle: const TextStyle(color: AppColors.danger, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: makeBorder(border),
      enabledBorder: makeBorder(border),
      focusedBorder: makeBorder(focus, 2),
      errorBorder: makeBorder(AppColors.danger),
      focusedErrorBorder: makeBorder(AppColors.danger, 2),
    );
  }
}
