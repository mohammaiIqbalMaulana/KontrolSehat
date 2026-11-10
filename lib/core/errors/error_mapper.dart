import 'package:supabase_flutter/supabase_flutter.dart';

/// Mengubah error teknis menjadi pesan Indonesia untuk pengguna.
/// Pesan mentah (SQL, token, stack trace) tidak pernah ditampilkan (SEC-08).
abstract final class ErrorMapper {
  static const String network = 'Tidak ada koneksi. Coba lagi.';
  static const String generic = 'Terjadi kesalahan. Coba lagi.';
  static const String sessionEnded = 'Tidak terautentikasi';

  /// Pesan dari trigger dan fungsi database (PRD 11.7).
  static const List<String> databaseMessages = <String>[
    'Belum waktunya minum obat',
    'Dosis ini sudah terkunci',
    'Data dosis tidak boleh diubah',
    'Maksimal 4 jam per obat',
    'Pilih 1 sampai 4 jam yang berbeda',
    'Jam harus dalam format HH:mm',
    'Obat tidak ditemukan',
    'Tanggal mulai tidak boleh sebelum hari ini',
    'Tanggal mulai tidak dapat diubah',
    'Jadwal harus di masa depan',
    'Waktu pengukuran tidak boleh di masa depan',
    sessionEnded,
  ];

  static String message(Object error) {
    if (error is AuthException) return _auth(error);
    if (error is PostgrestException) return _database(error.message);
    if (_looksLikeNetwork(error.toString())) return network;
    return generic;
  }

  /// True bila error berarti sesi berakhir dan aplikasi harus ke Login.
  static bool isSessionEnded(Object error) =>
      error is PostgrestException && error.message.contains(sessionEnded);

  static String _auth(AuthException e) {
    if (e.runtimeType.toString().contains('Retryable') ||
        _looksLikeNetwork(e.toString())) {
      return network;
    }
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      // Tidak menyebut mana yang salah (FR-102).
      return 'Email atau password salah';
    }
    if (msg.contains('already registered') || msg.contains('already exists')) {
      return 'Email sudah terdaftar';
    }
    if (msg.contains('password')) {
      return generic;
    }
    return generic;
  }

  static String _database(String raw) {
    for (final known in databaseMessages) {
      if (raw.contains(known)) return known;
    }
    if (_looksLikeNetwork(raw)) return network;
    return generic;
  }

  static bool _looksLikeNetwork(String text) {
    final t = text.toLowerCase();
    return t.contains('socketexception') ||
        t.contains('failed host lookup') ||
        t.contains('clientexception') ||
        t.contains('timeoutexception') ||
        t.contains('connection refused') ||
        t.contains('network is unreachable');
  }
}
