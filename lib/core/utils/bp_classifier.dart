/// Klasifikasi tekanan darah (PRD 8.4). Edukatif, bukan diagnosis.
/// Urutan evaluasi penting: kategori pertama yang cocok berlaku.
enum BpCategory {
  veryHigh('very_high', 'Sangat tinggi'),
  high('high', 'Tinggi'),
  low('low', 'Rendah'),
  elevated('elevated', 'Waspada'),
  normal('normal', 'Normal');

  const BpCategory(this.dbValue, this.label);

  /// Nilai kolom `bp_records.category` di database.
  final String dbValue;
  final String label;

  static BpCategory fromDb(String value) =>
      BpCategory.values.firstWhere((c) => c.dbValue == value);

  String get advice => switch (this) {
    BpCategory.normal => 'Tekanan darah dalam rentang normal. Lanjutkan pola hidup sehat dan minum obat sesuai anjuran dokter.',
    BpCategory.elevated => 'Sedikit di atas normal. Ukur lagi secara teratur dan jaga pola hidup sehat.',
    BpCategory.high => 'Tekanan darah tinggi. Pastikan obat diminum sesuai resep dan konsultasikan ke tenaga kesehatan.',
    BpCategory.veryHigh => 'Sangat tinggi. Duduk tenang dan ukur ulang setelah 5 menit. Bila tetap tinggi atau muncul nyeri dada, sesak, sakit kepala berat, atau lemah pada satu sisi tubuh, segera ke fasilitas kesehatan atau IGD.',
    BpCategory.low => 'Lebih rendah dari batas umum. Bila pusing atau lemas, duduk atau berbaring dan hubungi tenaga kesehatan.',
  };
}

BpCategory classifyBp(int systolic, int diastolic) {
  if (systolic >= 180 || diastolic >= 120) return BpCategory.veryHigh;
  if (systolic >= 140 || diastolic >= 90) return BpCategory.high;
  if (systolic < 90 || diastolic < 60) return BpCategory.low;
  if (systolic >= 120 || diastolic >= 80) return BpCategory.elevated;
  return BpCategory.normal;
}
