import 'package:supabase_flutter/supabase_flutter.dart';

import 'stats_models.dart';

class StatsRepository {
  StatsRepository(this._client);

  final SupabaseClient _client;

  Future<List<AdherenceDay>> fetchAdherence({
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'adherence_by_day',
      params: <String, Object>{
        'p_from': _dateOnly(from),
        'p_to': _dateOnly(to),
      },
    );
    return rows
        .whereType<Map<String, dynamic>>()
        .map(AdherenceDay.fromJson)
        .toList();
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
