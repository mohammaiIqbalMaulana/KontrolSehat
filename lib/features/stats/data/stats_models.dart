class AdherenceDay {
  const AdherenceDay({
    required this.day,
    required this.due,
    required this.taken,
  });

  factory AdherenceDay.fromJson(Map<String, dynamic> json) => AdherenceDay(
    day: DateTime.parse(json['day'] as String),
    due: (json['due'] as num?)?.toInt() ?? 0,
    taken: (json['taken'] as num?)?.toInt() ?? 0,
  );

  final DateTime day;
  final int due;
  final int taken;

  int get percent => due == 0 ? 0 : (taken * 100 / due).round();
}
