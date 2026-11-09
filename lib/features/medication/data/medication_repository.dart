import 'package:supabase_flutter/supabase_flutter.dart';

import 'medication_models.dart';

class MedicationRepository {
  MedicationRepository(this._client);

  final SupabaseClient _client;
  List<MedicineCatalogItem>? _catalogCache;

  Future<List<Medication>> fetchAll() async {
    final rows = await _client
        .from('medications')
        .select(
          'id, name, dosage, notes, start_date, end_date, is_active, medication_times(id, time_of_day)',
        )
        .order('is_active', ascending: false)
        .order('name');
    return rows
        .whereType<Map<String, dynamic>>()
        .map(Medication.fromJson)
        .toList();
  }

  Future<List<MedicineCatalogItem>> fetchCatalog() async {
    final cached = _catalogCache;
    if (cached != null) return cached;
    final rows = await _client
        .from('medicine_catalog')
        .select('id, name, drug_class, common_strengths')
        .order('name');
    _catalogCache = rows
        .whereType<Map<String, dynamic>>()
        .map(MedicineCatalogItem.fromJson)
        .toList();
    return _catalogCache ?? <MedicineCatalogItem>[];
  }

  Future<Medication> create({
    required String name,
    required String dosage,
    required DateTime startDate,
    required DateTime? endDate,
    required String? notes,
    required List<String> times,
  }) async {
    final row = await _client
        .from('medications')
        .insert(<String, Object?>{
          'name': name.trim(),
          'dosage': dosage.trim(),
          'start_date': _dateOnly(startDate),
          'end_date': endDate == null ? null : _dateOnly(endDate),
          'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
          'is_active': true,
        })
        .select(
          'id, name, dosage, notes, start_date, end_date, is_active, medication_times(id, time_of_day)',
        )
        .single();
    final medication = Medication.fromJson(row);
    try {
      await applySchedule(medication.id, times);
      return medication;
    } on Object {
      await _client.from('medications').delete().eq('id', medication.id);
      rethrow;
    }
  }

  Future<void> applySchedule(String id, List<String> times) async {
    await _client.rpc<Object?>(
      'apply_schedule_change',
      params: <String, Object>{'p_medication_id': id, 'p_times': times},
    );
  }

  Future<void> update({
    required String id,
    required String name,
    required String dosage,
    required DateTime? endDate,
    required String? notes,
    required List<String> times,
  }) async {
    await _client
        .from('medications')
        .update(<String, Object?>{
          'name': name.trim(),
          'dosage': dosage.trim(),
          'end_date': endDate == null ? null : _dateOnly(endDate),
          'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
        })
        .eq('id', id);
    await applySchedule(id, times);
  }

  Future<void> toggleActive(String id, bool active) async {
    await _client
        .from('medications')
        .update(<String, Object>{'is_active': active})
        .eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('medications').delete().eq('id', id);
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
