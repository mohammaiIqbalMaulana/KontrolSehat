import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_gate.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
  ThemeMode.system,
);

class KontrolSehatApp extends StatelessWidget {
  const KontrolSehatApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: themeModeNotifier,
    builder: (context, mode, _) => MaterialApp(
      title: 'KontrolSehat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      home: const AuthGate(),
    ),
  );
}

/// Ditampilkan bila `env.json` tidak diberikan atau berisi kunci terlarang.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Konfigurasi belum benar.\n\n'
            'Jalankan dengan:\n'
            'flutter run --dart-define-from-file=env.json\n\n'
            'Pastikan memakai kunci publishable (sb_publishable_...), '
            'bukan kunci secret.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
