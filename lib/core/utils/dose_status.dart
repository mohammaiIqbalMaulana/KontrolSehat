/// Status tampilan satu dosis obat (PRD Bagian 8.1).
/// Ditentukan dari data `status` dan waktu saat ini pada zona waktu profil.
enum DoseStatus {
  notYetTime('Belum waktunya', canAction: false),
  timeToTake('Waktunya minum', canAction: true),
  late('Terlambat', canAction: true),
  taken('Sudah minum', canAction: false),
  skipped('Dilewati', canAction: false),
  missed('Terlewat', canAction: false);

  const DoseStatus(this.label, {required this.canAction});

  final String label;
  final bool canAction;
}

/// Menghitung status tampilan dosis berdasarkan PRD 8.1.
/// [rawStatus] adalah kolom `status` di tabel `medication_logs` ('pending', 'taken', 'skipped').
/// [scheduledAt] dan [now] harus sudah dalam zona waktu profil pengguna.
DoseStatus evaluateDoseStatus({
  required String rawStatus,
  required DateTime scheduledAt,
  required DateTime now,
}) {
  if (rawStatus == 'taken') return DoseStatus.taken;
  if (rawStatus == 'skipped') return DoseStatus.skipped;

  // Tanggal kalender
  final scheduledDate = DateTime(
    scheduledAt.year,
    scheduledAt.month,
    scheduledAt.day,
  );
  final nowDate = DateTime(now.year, now.month, now.day);

  // Jika tanggal sudah lewat (sebelum hari ini), otomatis Terlewat
  if (scheduledDate.isBefore(nowDate)) {
    return DoseStatus.missed;
  }

  // Jika tanggal di masa depan (besok atau lebih), otomatis Belum waktunya
  if (scheduledDate.isAfter(nowDate)) {
    return DoseStatus.notYetTime;
  }

  // Hari ini: periksa jendela menit
  final diffMinutes = now.difference(scheduledAt).inMinutes;

  if (diffMinutes < -60) {
    return DoseStatus.notYetTime;
  } else if (diffMinutes <= 120) {
    return DoseStatus.timeToTake;
  } else {
    return DoseStatus.late;
  }
}
