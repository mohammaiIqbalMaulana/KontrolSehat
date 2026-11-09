import 'package:supabase_flutter/supabase_flutter.dart';

import 'bp_model.dart';

class BpRepository {
  BpRepository(this._client);

  final SupabaseClient _client;

  static const String _columns =
      'id, systolic, diastolic, pulse, measured_at, note, category';

  Future<BpRecord?> fetchLatest() async {
    final rows = await _client
        .from('bp_records')
        .select(_columns)
        .order('measured_at', ascending: false)
        .limit(1);
    return rows.isEmpty ? null : BpRecord.fromJson(rows.first);
  }

  Future<List<BpRecord>> fetchHistory({DateTime? since}) async {
    var query = _client.from('bp_records').select(_columns);
    if (since != null) {
      query = query.gte('measured_at', since.toUtc().toIso8601String());
    }
    final rows = await query.order('measured_at', ascending: false);
    return rows
        .whereType<Map<String, dynamic>>()
        .map(BpRecord.fromJson)
        .toList();
  }

  Future<void> delete(String id) async {
    await _client.from('bp_records').delete().eq('id', id);
  }

  Future<BpRecord> create({
    required int systolic,
    required int diastolic,
    required int? pulse,
    required DateTime measuredAt,
    required String? note,
  }) async {
    final row = await _client
        .from('bp_records')
        .insert(<String, Object?>{
          'systolic': systolic,
          'diastolic': diastolic,
          'pulse': pulse,
          'measured_at': measuredAt.toUtc().toIso8601String(),
          'note': note?.trim().isEmpty == true ? null : note?.trim(),
        })
        .select(_columns)
        .single();
    return BpRecord.fromJson(row);
  }
}
