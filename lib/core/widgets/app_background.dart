import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Latar gradien mengikuti mode tema agar kontras tetap baik (PRD 13.2).
class AppBackground extends StatelessWidget {
  const AppBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const <Color>[Color(0xFF12142B), Color(0xFF1C1F3D)]
              : const <Color>[AppColors.gradientTop, AppColors.gradientBottom],
        ),
      ),
      child: child,
    );
  }
}
