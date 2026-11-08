import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Latar gradien biru ke lavender (PRD 13.2).
class AppBackground extends StatelessWidget {
  const AppBackground({required this.child, super.key});

  final Widget child;

  static const BoxDecoration _decoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[AppColors.gradientTop, AppColors.gradientBottom],
    ),
  );

  @override
  Widget build(BuildContext context) =>
      DecoratedBox(decoration: _decoration, child: child);
}
