import 'package:supabase_flutter/supabase_flutter.dart';

class DosesRepository {
  DosesRepository(this._client);

  final SupabaseClient _client;

  /// Menyusul dosis (FR-207, NFR-09): idempoten, aman dipanggil berulang.
  /// Dipanggil saat aplikasi dibuka dan setelah login.
  Future<void> ensureDoses({int daysAhead = 7}) async {
    await _client.rpc<Object?>(
      'ensure_doses',
      params: <String, Object>{'p_days_ahead': daysAhead},
    );
  }
}
