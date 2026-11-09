import 'package:supabase_flutter/supabase_flutter.dart';

import 'appointment_model.dart';

class AppointmentRepository {
  AppointmentRepository(this._client);

  final SupabaseClient _client;

  Future<List<Appointment>> fetchAll() async {
    final rows = await _client
        .from('appointments')
        .select('id, title, facility, doctor, scheduled_at, notes, status')
        .order('scheduled_at');
    return rows
        .whereType<Map<String, dynamic>>()
        .map(Appointment.fromJson)
        .toList();
  }

  Future<Appointment?> fetchNearest() async {
    final rows = await _client
        .from('appointments')
        .select('id, title, facility, doctor, scheduled_at, notes, status')
        .eq('status', 'upcoming')
        .gte('scheduled_at', DateTime.now().toUtc().toIso8601String())
        .order('scheduled_at')
        .limit(1);
    return rows.isEmpty ? null : Appointment.fromJson(rows.first);
  }

  Future<Appointment> create({
    required String title,
    required String facility,
    required String? doctor,
    required DateTime scheduledAt,
    required String? notes,
  }) async {
    final row = await _client
        .from('appointments')
        .insert(<String, Object?>{
          'title': title.trim(),
          'facility': facility.trim(),
          'doctor': doctor?.trim().isEmpty == true ? null : doctor?.trim(),
          'scheduled_at': scheduledAt.toUtc().toIso8601String(),
          'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
        })
        .select('id, title, facility, doctor, scheduled_at, notes, status')
        .single();
    return Appointment.fromJson(row);
  }

  Future<void> updateStatus(String id, String status) async {
    await _client
        .from('appointments')
        .update(<String, Object>{'status': status})
        .eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('appointments').delete().eq('id', id);
  }
}
