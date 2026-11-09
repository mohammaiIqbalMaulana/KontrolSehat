import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Jam dinding mengikuti zona waktu profil pengguna (NFR-10, PRD A12),
/// bukan zona perangkat. Semua nilai yang dikembalikan adalah
/// `TZDateTime` (turunan `DateTime`), jadi perbandingan antar-instan tetap
/// benar sedangkan `year/month/day/hour` mengikuti zona profil.
abstract final class AppTime {
  static bool _dbReady = false;
  static tz.Location _location = tz.UTC;
  static bool _zoneKnown = false;
  static String? _userId;

  static void _ensureDb() {
    if (_dbReady) return;
    tz_data.initializeTimeZones();
    _dbReady = true;
  }

  /// Zona sudah diketahui untuk [userId] ini.
  static bool isLoadedFor(String? userId) =>
      _zoneKnown && userId != null && userId == _userId;

  /// Menyetel zona dari profil. Nama tidak dikenal memakai Asia/Jakarta.
  static void setZone(String name, {String? userId}) {
    _ensureDb();
    try {
      _location = tz.getLocation(name);
    } on Object {
      _location = tz.getLocation('Asia/Jakarta');
    }
    _zoneKnown = true;
    _userId = userId;
  }

  /// Dipakai saat logout agar akun berikutnya memuat ulang zonanya.
  static void reset() {
    _zoneKnown = false;
    _userId = null;
  }

  static tz.Location get location {
    _ensureDb();
    if (!_zoneKnown) _location = tz.getLocation('Asia/Jakarta');
    return _location;
  }

  static tz.TZDateTime now() => tz.TZDateTime.now(location);

  /// Mengubah instan (biasanya UTC dari database) ke jam dinding zona profil.
  static tz.TZDateTime toZone(DateTime instant) =>
      tz.TZDateTime.from(instant, location);

  /// Membentuk instan dari isian tanggal+jam pengguna di zona profil.
  static tz.TZDateTime wall(
    int year,
    int month,
    int day, [
    int hour = 0,
    int minute = 0,
  ]) => tz.TZDateTime(location, year, month, day, hour, minute);

  /// Awal hari ini (00:00) di zona profil, dalam UTC.
  static DateTime startOfTodayUtc() {
    final n = now();
    return wall(n.year, n.month, n.day).toUtc();
  }

  /// Awal hari berikutnya (00:00) di zona profil, dalam UTC.
  static DateTime startOfTomorrowUtc() {
    final n = now();
    return wall(n.year, n.month, n.day + 1).toUtc();
  }
}
