/// Zona waktu IANA untuk profil saat registrasi (PRD A12). Dipilih dari
/// offset perangkat tanpa paket tambahan; di luar Indonesia memakai
/// Asia/Jakarta (database juga menolak zona tidak valid).
abstract final class DeviceTimezone {
  static String detect({Duration? offset}) {
    final hours = (offset ?? DateTime.now().timeZoneOffset).inHours;
    return switch (hours) {
      8 => 'Asia/Makassar',
      9 => 'Asia/Jayapura',
      _ => 'Asia/Jakarta',
    };
  }
}
