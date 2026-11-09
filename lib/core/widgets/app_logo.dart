import 'package:flutter/material.dart';

/// Logo KontrolSehat. Pada tema terang tampil apa adanya. Pada tema gelap
/// logo diberi lingkaran terang karena separuh perisainya hitam dan akan
/// menyatu dengan latar.
class AppLogo extends StatelessWidget {
  const AppLogo({this.height = 96, super.key});

  static const String asset = 'assets/images/logo.png';

  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final image = Image.asset(
      asset,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'Logo KontrolSehat',
    );
    if (!isDark) return image;

    final pad = height * 0.16;
    final diameter = height + pad * 2;
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F3FF),
        shape: BoxShape.circle,
      ),
      child: image,
    );
  }
}
