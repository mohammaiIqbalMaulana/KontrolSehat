/// Aturan input dari PRD bagian 10. Setiap fungsi mengembalikan pesan
/// error (null bila valid), cocok untuk `TextFormField.validator`.
/// Semua teks di-trim sebelum dicek.
abstract final class Validators {
  static final RegExp _email = RegExp(
    r'^[A-Za-z0-9.!#$%&*+/=?^_{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
  );

  // ---------- 10.1 Akun dan profil
  static String? fullName(String? v) =>
      _length(v, 2, 50, 'Nama harus 2 sampai 50 karakter');

  /// Rentang: (tahun berjalan - 100) sampai (tahun berjalan - 18).
  static String? birthYear(String? v, {int? currentYear}) {
    final year = int.tryParse((v ?? '').trim());
    final now = currentYear ?? DateTime.now().year;
    if (year == null || year < now - 100 || year > now - 18) {
      return 'Tahun lahir tidak valid';
    }
    return null;
  }

  static String? email(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty || s.length > 254 || !_email.hasMatch(s)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  /// Registrasi: minimal 8 karakter, memuat huruf dan angka.
  static String? passwordRegister(String? v) {
    final s = v ?? '';
    final ok = s.length >= 8 &&
        RegExp('[A-Za-z]').hasMatch(s) &&
        RegExp('[0-9]').hasMatch(s);
    return ok
        ? null
        : 'Password minimal 8 karakter dan memuat huruf serta angka';
  }

  /// Login: hanya wajib diisi.
  static String? passwordLogin(String? v) =>
      (v ?? '').isEmpty ? 'Password wajib diisi' : null;

  // ---------- 10.2 Obat
  static String? medicationName(String? v) =>
      _length(v, 2, 60, 'Nama obat harus 2 sampai 60 karakter');

  static String? dosage(String? v) =>
      _length(v, 1, 30, 'Dosis wajib diisi, maksimal 30 karakter');

  static String? notes(String? v) =>
      _length(v, 0, 200, 'Catatan maksimal 200 karakter');

  // ---------- 10.3 Jadwal kontrol
  static String? appointmentTitle(String? v) =>
      _length(v, 2, 60, 'Judul harus 2 sampai 60 karakter');

  static String? facility(String? v) =>
      _length(v, 2, 80, 'Nama fasilitas harus 2 sampai 80 karakter');

  static String? doctor(String? v) =>
      _length(v, 0, 60, 'Maksimal 60 karakter');

  // ---------- 10.4 Tekanan darah
  static String? systolic(String? v) =>
      _intRange(v, 70, 250, 'Sistolik harus 70 sampai 250');

  static String? diastolic(String? v) =>
      _intRange(v, 40, 150, 'Diastolik harus 40 sampai 150');

  /// Opsional: kosong dianggap valid.
  static String? pulse(String? v) {
    if ((v ?? '').trim().isEmpty) return null;
    return _intRange(v, 30, 200, 'Nadi harus 30 sampai 200');
  }

  /// Dipanggil setelah sistolik dan diastolik masing-masing valid.
  static String? systolicAboveDiastolic(int systolic, int diastolic) =>
      systolic > diastolic ? null : 'Sistolik harus lebih besar dari diastolik';

  static String? measuredAt(DateTime value, {DateTime? now}) {
    final limit = (now ?? DateTime.now()).add(const Duration(minutes: 5));
    return value.isAfter(limit)
        ? 'Waktu pengukuran tidak boleh di masa depan'
        : null;
  }

  // ---------- pembantu
  static String? _length(String? v, int min, int max, String message) {
    final len = (v ?? '').trim().length;
    return (len < min || len > max) ? message : null;
  }

  static String? _intRange(String? v, int min, int max, String message) {
    final n = int.tryParse((v ?? '').trim());
    return (n == null || n < min || n > max) ? message : null;
  }
}
