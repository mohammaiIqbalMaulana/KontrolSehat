import 'package:supabase_flutter/supabase_flutter.dart';

/// Satu-satunya pintu ke Supabase Auth. Password tidak pernah disimpan
/// atau dicatat oleh aplikasi (SEC-01).
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get session => _client.auth.currentSession;

  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  Future<void> signIn({required String email, required String password}) =>
      _client.auth.signInWithPassword(email: email.trim(), password: password);

  /// Trigger `handle_new_user` membuat profil dari metadata ini.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required int birthYear,
    required String timezone,
  }) =>
      _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: <String, Object>{
          'full_name': fullName.trim(),
          'birth_year': birthYear,
          'timezone': timezone,
        },
      );

  Future<void> signOut() => _client.auth.signOut();
}
