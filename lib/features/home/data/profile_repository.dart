import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_time.dart';

class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    required this.birthYear,
    required this.timezone,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    fullName: json['full_name'] as String,
    birthYear: json['birth_year'] as int,
    timezone: json['timezone'] as String,
  );

  final String id;
  final String fullName;
  final int birthYear;
  final String timezone;

  String get firstName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? fullName : parts.first;
  }
}

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  /// RLS membatasi hasil ke baris milik pengguna sendiri.
  Future<Profile?> fetchMine() async {
    final row = await _client.from('profiles').select().maybeSingle();
    if (row == null) return null;
    final profile = Profile.fromJson(row);
    AppTime.setZone(profile.timezone, userId: profile.id);
    return profile;
  }

  /// Memastikan zona waktu profil sudah dimuat sebelum layar menghitung
  /// "hari ini" atau menampilkan jam (NFR-10). Tidak mengambil ulang bila
  /// zona untuk akun ini sudah diketahui.
  Future<void> ensureZone() async {
    final uid = _client.auth.currentUser?.id;
    if (AppTime.isLoadedFor(uid)) return;
    await fetchMine();
  }

  Future<void> updateMine({
    required String fullName,
    required int birthYear,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Belum login');
    // Filter id wajib: Supabase menolak UPDATE tanpa WHERE.
    await _client
        .from('profiles')
        .update(<String, Object>{
          'full_name': fullName.trim(),
          'birth_year': birthYear,
        })
        .eq('id', uid);
  }
}
