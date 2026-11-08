import 'package:flutter/material.dart';

/// Kartu putih bersudut 24 dp dengan bayangan lembut (PRD 13.2).
class SoftCard extends StatelessWidget {
  const SoftCard({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  static const BoxDecoration _decoration = BoxDecoration(
    color: Color(0xD9FFFFFF), // putih 85 persen
    borderRadius: BorderRadius.all(Radius.circular(24)),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: Color(0x146C4CE0),
        blurRadius: 16,
        offset: Offset(0, 6),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: _decoration,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(20),
          child: child,
        ),
      );
}
