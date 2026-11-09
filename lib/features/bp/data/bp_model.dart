import '../../../core/utils/bp_classifier.dart';

class BpRecord {
  const BpRecord({
    required this.id,
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.measuredAt,
    required this.note,
    required this.category,
  });

  factory BpRecord.fromJson(Map<String, dynamic> json) => BpRecord(
    id: json['id'] as String,
    systolic: json['systolic'] as int,
    diastolic: json['diastolic'] as int,
    pulse: json['pulse'] as int?,
    measuredAt: DateTime.parse(json['measured_at'] as String),
    note: json['note'] as String?,
    category: BpCategory.fromDb(json['category'] as String),
  );

  final String id;
  final int systolic;
  final int diastolic;
  final int? pulse;
  final DateTime measuredAt;
  final String? note;
  final BpCategory category;
}
