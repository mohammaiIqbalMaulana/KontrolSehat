import 'package:flutter/material.dart';

/// Membatasi lebar isi (NFR-02): satu kolom di layar sempit, tidak
/// melebar berlebihan di tablet. Padding layar 20 dp (PRD 13.2).
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    required this.child,
    this.maxWidth = 560,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: child,
          ),
        ),
      );
}
