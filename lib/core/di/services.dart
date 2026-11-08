import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/home/data/profile_repository.dart';
import '../../features/medication/data/doses_repository.dart';

/// Penyedia repository tunggal. Diisi sekali di `main` setelah Supabase
/// siap. Halaman membaca dari sini; controller menerima repository lewat
/// konstruktor agar mudah diuji.
abstract final class Services {
  static late final AuthRepository auth;
  static late final ProfileRepository profiles;
  static late final DosesRepository doses;

  static void init(SupabaseClient client) {
    auth = AuthRepository(client);
    profiles = ProfileRepository(client);
    doses = DosesRepository(client);
  }
}
