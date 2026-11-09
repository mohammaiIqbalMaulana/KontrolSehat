import 'package:supabase_flutter/supabase_flutter.dart';

import 'medication_models.dart';

class DosesRepository {
  DosesRepository(this._client);

  final SupabaseClient _client;

  /// Menyusul dosis (FR-207, NFR-09): idempoten, aman dipanggil berulang.
  /// Dipanggil saat aplikasi dibuka dan setelah login.
  Future<void> ensureDoses({int daysAhead = 7}) async {
    await _client.rpc<Object?>(
      'ensure_doses',
      params: <String, Object>{'p_days_ahead': daysAhead},
    );
  }

  Future<List<MedicationLog>> fetchToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0).toUtc();
    final endOfDay = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
      999,
    ).toUtc();

    final rows = await _client
        .from('medication_logs')
        .select(
          'id, medication_id, scheduled_at, status, medications(name, dosage)',
        )
        .gte('scheduled_at', startOfDay.toIso8601String())
        .lte('scheduled_at', endOfDay.toIso8601String())
        .order('scheduled_at');
    return rows
        .whereType<Map<String, dynamic>>()
        .map(MedicationLog.fromJson)
        .toList();
  }

  Future<List<MedicationLog>> fetchPendingAhead({int daysAhead = 7}) async {
    final now = DateTime.now().toUtc();
    final until = now.add(Duration(days: daysAhead));
    final rows = await _client
        .from('medication_logs')
        .select(
          'id, medication_id, scheduled_at, status, medications(name, dosage)',
        )
        .eq('status', 'pending')
        .gte('scheduled_at', now.toIso8601String())
        .lte('scheduled_at', until.toIso8601String())
        .order('scheduled_at');
    return rows
        .whereType<Map<String, dynamic>>()
        .map(MedicationLog.fromJson)
        .toList();
  }

  Future<MedicationLog> updateStatus({
    required String id,
    required String status,
  }) async {
    final row = await _client
        .from('medication_logs')
        .update(<String, Object>{'status': status})
        .eq('id', id)
        .select(
          'id, medication_id, scheduled_at, status, medications(name, dosage)',
        )
        .single();
    return MedicationLog.fromJson(row);
  }
}
