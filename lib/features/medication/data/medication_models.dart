class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.notes,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.times,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    final rawTimes = json['medication_times'];
    final times = rawTimes is List
        ? rawTimes
              .whereType<Map<String, dynamic>>()
              .map(MedicationTime.fromJson)
              .toList()
        : <MedicationTime>[];
    return Medication(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      notes: json['notes'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: _parseDate(json['end_date']),
      isActive: json['is_active'] as bool,
      times: List<MedicationTime>.unmodifiable(times),
    );
  }

  final String id;
  final String name;
  final String dosage;
  final String? notes;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final List<MedicationTime> times;

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}

class MedicationTime {
  const MedicationTime({required this.id, required this.timeOfDay});

  factory MedicationTime.fromJson(Map<String, dynamic> json) => MedicationTime(
    id: json['id'] as String,
    timeOfDay: json['time_of_day'] as String,
  );

  final String id;
  final String timeOfDay;
}

class MedicineCatalogItem {
  const MedicineCatalogItem({
    required this.id,
    required this.name,
    required this.drugClass,
    required this.commonStrengths,
  });

  factory MedicineCatalogItem.fromJson(Map<String, dynamic> json) =>
      MedicineCatalogItem(
        id: json['id'] as String,
        name: json['name'] as String,
        drugClass: json['drug_class'] as String,
        commonStrengths: List<String>.from(json['common_strengths'] as List),
      );

  final String id;
  final String name;
  final String drugClass;
  final List<String> commonStrengths;
}

class MedicationLog {
  const MedicationLog({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.scheduledAt,
    required this.status,
  });

  factory MedicationLog.fromJson(Map<String, dynamic> json) {
    final medication = json['medications'];
    final medicationJson = medication is Map<String, dynamic>
        ? medication
        : const <String, dynamic>{};
    return MedicationLog(
      id: json['id'] as String,
      medicationId: json['medication_id'] as String,
      medicationName: medicationJson['name'] as String? ?? 'Obat',
      dosage: medicationJson['dosage'] as String? ?? '',
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      status: json['status'] as String,
    );
  }

  final String id;
  final String medicationId;
  final String medicationName;
  final String dosage;
  final DateTime scheduledAt;
  final String status;
}
