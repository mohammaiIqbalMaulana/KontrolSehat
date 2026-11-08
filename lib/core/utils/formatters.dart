/// Format tampilan (NFR-08): tanggal "d MMM yyyy", jam "HH:mm", bahasa
/// Indonesia. Dibuat tanpa data locale supaya hasilnya deterministik.
abstract final class Fmt {
  static const List<String> _months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', //
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static String date(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  static String time(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Hitung mundur kontrol (PRD 8.6). [scheduled] dan [now] harus sudah
  /// dalam zona waktu yang sama (zona profil pengguna).
  static String countdown(DateTime scheduled, DateTime now) {
    final days = DateTime(scheduled.year, scheduled.month, scheduled.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (days == 0) return 'Hari ini, ${time(scheduled)}';
    if (days == 1) return 'Besok, ${time(scheduled)}';
    if (days >= 2 && days <= 30) return '$days hari lagi';
    return date(scheduled);
  }

  /// Persentase kepatuhan (PRD 8.2). Null bila tidak ada dosis jatuh tempo
  /// (ditampilkan "–", bukan 0 persen).
  static int? adherencePercent({required int taken, required int due}) {
    if (due <= 0) return null;
    return (taken * 100 / due).round();
  }

  static String adherenceLabel({required int taken, required int due}) {
    final p = adherencePercent(taken: taken, due: due);
    return p == null ? '–' : '$p%';
  }
}
