import 'package:flutter/material.dart';

/// Kartu permukaan memakai ColorScheme agar terbaca pada tema terang dan gelap.
class SoftCard extends StatelessWidget {
  const SoftCard({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? colors.surfaceContainer : colors.surface;
    return Material(
      color: surface,
      elevation: isDark ? 2 : 1,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}
