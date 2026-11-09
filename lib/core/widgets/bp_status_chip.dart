import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/bp_classifier.dart';

/// Label kategori BP: selalu menggabungkan ikon dan teks, dengan warna
/// permukaan yang mengikuti tema (NFR-03, PRD 13.2).
class BpStatusChip extends StatelessWidget {
  const BpStatusChip({required this.category, super.key});

  final BpCategory category;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (icon, lightBg, darkBg, lightInk, darkInk) = switch (category) {
      BpCategory.normal => (
        Icons.check_circle_outline,
        AppColors.bpNormal,
        const Color(0xFF183D34),
        const Color(0xFF174B37),
        const Color(0xFFB5F0D2),
      ),
      BpCategory.elevated => (
        Icons.info_outline,
        AppColors.bpElevated,
        const Color(0xFF493B1A),
        const Color(0xFF55420C),
        const Color(0xFFFFE6A3),
      ),
      BpCategory.high => (
        Icons.warning_amber_rounded,
        AppColors.bpHigh,
        const Color(0xFF4B2C20),
        const Color(0xFF6C3517),
        const Color(0xFFFFC7A3),
      ),
      BpCategory.veryHigh => (
        Icons.error_outline,
        AppColors.bpVeryHigh,
        const Color(0xFF4C252B),
        const Color(0xFF762B36),
        const Color(0xFFFFB9C1),
      ),
      BpCategory.low => (
        Icons.south_rounded,
        AppColors.bpLow,
        const Color(0xFF1E3449),
        const Color(0xFF20466A),
        const Color(0xFFB5DBFF),
      ),
    };
    final background = dark ? darkBg : lightBg;
    final ink = dark ? darkInk : lightInk;

    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ink.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: ink),
          const SizedBox(width: 6),
          Text(
            category.label,
            style: TextStyle(
              color: ink,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
