import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/services.dart';
import '../../home/presentation/home_page.dart';
import 'login_page.dart';

/// Memilih Login atau Beranda dari status sesi (FR-103). Token diperbarui
/// otomatis oleh Supabase; logout atau sesi berakhir kembali ke Login.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
        stream: Services.auth.authChanges,
        builder: (context, snapshot) {
          final session = snapshot.data?.session ?? Services.auth.session;
          return session == null ? const LoginPage() : const HomePage();
        },
      );
}
