import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';
import '../domain/elog_entry.dart';

class EntriesRepository {
  EntriesRepository(this._client);

  final SupabaseClient _client;

  Future<List<ElogEntry>> listEntries({
    required String moduleType,
    String? search,
  }) async {
    final query = _client
        .from('elog_entries')
        .select(
          '*, profiles:created_by (name, designation, centre, employee_id)',
        )
        .eq('module_type', moduleType)
        .order('updated_at', ascending: false);

    final response = await query;
    final rows = (response as List).cast<Map<String, dynamic>>();
    var entries = rows.map(ElogEntry.fromMap).toList();
    if (search != null && search.trim().isNotEmpty) {
      final needle = search.toLowerCase();
      entries = entries.where((e) {
        final matchPatient = e.patientUniqueId.toLowerCase().contains(needle);
        final matchMrn = e.mrn.toLowerCase().contains(needle);
        final matchKeyword = e.keywords.any(
          (k) => k.toLowerCase().contains(needle),
        );
        return matchPatient || matchMrn || matchKeyword;
      }).toList();
    }
    return entries;
  }

  Future<ElogEntry> getEntry(String id) async {
    final response = await _client
        .from('elog_entries')
        .select(
          '*, profiles:created_by (name, designation, centre, employee_id)',
        )
        .eq('id', id)
        .maybeSingle();
    if (response == null) {
      throw PostgrestException(message: 'Entry not found', code: '404');
    }
    return ElogEntry.fromMap(Map<String, dynamic>.from(response));
  }

  Future<String> createEntry(ElogEntryCreate data) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw AuthException('Not signed in');
    }
    final insert = data.toInsertMap(userId);
    final response = await _client
        .from('elog_entries')
        .insert(insert)
        .select('id')
        .maybeSingle();
    if (response == null || response['id'] == null) {
      throw PostgrestException(message: 'Unable to create entry');
    }
    return response['id'] as String;
  }

  Future<void> updateEntry(String id, ElogEntryUpdate patch) async {
    final update = patch.toUpdateMap();
    await _client.from('elog_entries').update(update).eq('id', id);
  }

  Future<void> deleteEntry(String id) async {
    await _client.from('elog_entries').delete().eq('id', id);
  }
}

final entriesRepositoryProvider = Provider<EntriesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return EntriesRepository(client);
});
