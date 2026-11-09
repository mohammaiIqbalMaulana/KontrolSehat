class Appointment {
  const Appointment({
    required this.id,
    required this.title,
    required this.facility,
    required this.doctor,
    required this.scheduledAt,
    required this.notes,
    required this.status,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'] as String,
    title: json['title'] as String,
    facility: json['facility'] as String,
    doctor: json['doctor'] as String?,
    scheduledAt: DateTime.parse(json['scheduled_at'] as String),
    notes: json['notes'] as String?,
    status: json['status'] as String,
  );

  final String id;
  final String title;
  final String facility;
  final String? doctor;
  final DateTime scheduledAt;
  final String? notes;
  final String status;

  bool get isPast => scheduledAt.isBefore(DateTime.now().toUtc());
}
