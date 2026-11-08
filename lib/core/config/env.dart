/// Konfigurasi dari `--dart-define-from-file=env.json` (SEC-03).
/// Berkas env.json tidak boleh di-commit.
abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseKey = String.fromEnvironment('SUPABASE_KEY');

  /// Valid bila URL berskema https dan kunci bukan kunci rahasia.
  /// Kunci `sb_secret_` dan `service_role` tidak boleh ada di aplikasi.
  static bool get isConfigured =>
      supabaseUrl.startsWith('https://') &&
      supabaseKey.isNotEmpty &&
      !isForbiddenKey(supabaseKey);

  static bool isForbiddenKey(String key) =>
      key.startsWith('sb_secret_') || key.contains('service_role');
}
