import 'package:flutter/material.dart';

/// Tampilan kosong beserta ilustrasi ikon dan teks (FR-705).
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.message,
    this.height = 160,
    super.key,
  });

  final IconData icon;
  final String message;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
