import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/services.dart';
import '../../onboarding/presentation/onboarding_page.dart';
import '../../shell/presentation/main_shell.dart';
import '../../splash/presentation/splash_page.dart';
import 'login_page.dart';

/// Memilih Splash, Onboarding, Login, atau Beranda dari status sesi (FR-103).
/// Splash tampil minimal sebentar saat aplikasi dibuka, tidak lagi setelah
/// logout.
class AuthGate extends StatefulWidget {
  const AuthGate({this.skipSplash = false, super.key});

  /// Dipakai setelah onboarding supaya splash tidak diulang.
  final bool skipSplash;

  static const Duration minSplash = Duration(milliseconds: 1800);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late bool _splashDone = widget.skipSplash;

  @override
  void initState() {
    super.initState();
    if (_splashDone) return;
    Future<void>.delayed(AuthGate.minSplash).then((_) {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  Widget _destination() => StreamBuilder<AuthState>(
    stream: Services.auth.authChanges,
    builder: (context, snapshot) {
      final session = snapshot.data?.session ?? Services.auth.session;
      if (session != null) return const MainShell(key: ValueKey('home'));

      return FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, prefSnap) {
          if (!prefSnap.hasData) return const SplashPage();
          final hasSeen =
              prefSnap.data?.getBool(OnboardingPage.prefKey) ?? false;
          return hasSeen
              ? const LoginPage(key: ValueKey('login'))
              : const OnboardingPage(key: ValueKey('onboarding'));
        },
      );
    },
  );

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 350),
    child: _splashDone
        ? _destination()
        : const SplashPage(key: ValueKey('splash')),
  );
}
