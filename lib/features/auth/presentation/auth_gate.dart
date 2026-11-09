import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/services.dart';
import '../../onboarding/presentation/onboarding_page.dart';
import '../../shell/presentation/main_shell.dart';
import 'login_page.dart';

/// Memilih Onboarding, Login, atau Beranda dari status sesi (FR-103).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: Services.auth.authChanges,
    builder: (context, snapshot) {
      final session = snapshot.data?.session ?? Services.auth.session;
      if (session != null) return const MainShell();

      return FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, prefSnap) {
          if (!prefSnap.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final hasSeen =
              prefSnap.data?.getBool(OnboardingPage.prefKey) ?? false;
          return hasSeen ? const LoginPage() : const OnboardingPage();
        },
      );
    },
  );
}
