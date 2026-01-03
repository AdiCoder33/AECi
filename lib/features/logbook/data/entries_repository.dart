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
    bool onlyMine = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _client
        .from('elog_entries')
        .select('*')
        .eq('module_type', moduleType)
        .order('updated_at', ascending: false);
    final rows = (response as List).cast<Map<String, dynamic>>();
    var entries = rows.map(ElogEntry.fromMap).toList();
    if (onlyMine) {
      final uid = _client.auth.currentUser?.id;
      if (uid != null) {
        entries = entries.where((e) => e.createdBy == uid).toList();
      }
    }
    if (startDate != null) {
      entries = entries.where((e) => !e.createdAt.isBefore(startDate)).toList();
    }
    if (endDate != null) {
      entries = entries.where((e) => !e.createdAt.isAfter(endDate)).toList();
    }
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
    final row =
        await _client.from('elog_entries').select('*').eq('id', id).maybeSingle();
    if (row == null) {
      throw PostgrestException(message: 'Entry not found', code: '404');
    }
    final map = Map<String, dynamic>.from(row);

    // Fetch author profile
    final createdBy = map['created_by'] as String;
    final author = await _client
        .from('profiles')
        .select('name, designation, centre, employee_id')
        .eq('id', createdBy)
        .maybeSingle();
    if (author != null) {
      map['author_profile'] = author;
    }

    // Fetch reviewer profile if exists
    final reviewerId = map['reviewed_by'] as String?;
    if (reviewerId != null) {
      final reviewer = await _client
          .from('profiles')
          .select('name, designation, centre, employee_id')
          .eq('id', reviewerId)
          .maybeSingle();
      if (reviewer != null) {
        map['reviewer_profile'] = reviewer;
      }
    }

    return ElogEntry.fromMap(map);
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

  Future<List<ElogEntry>> listEntriesForTrainees({
    required List<String> traineeIds,
    List<String>? statuses,
    String? reviewedBy,
  }) async {
    if (traineeIds.isEmpty) return [];
    final uniqueIds = traineeIds.toSet().toList();
    final quotedTrainees = uniqueIds.map((id) => '"$id"').join(',');
    final quotedModules = moduleTypes.map((m) => '"$m"').join(',');
    var query = _client
        .from('elog_entries')
        .select('*')
        .filter('created_by', 'in', '($quotedTrainees)')
        .filter('module_type', 'in', '($quotedModules)');
    if (statuses != null && statuses.isNotEmpty) {
      final quotedStatuses = statuses.map((s) => '"$s"').join(',');
      query = query.filter('status', 'in', '($quotedStatuses)');
    }
    if (reviewedBy != null && reviewedBy.isNotEmpty) {
      query = query.eq('reviewed_by', reviewedBy);
    }
    final response = await query.order('updated_at', ascending: false);
    final rows = (response as List).cast<Map<String, dynamic>>();
    return rows.map(ElogEntry.fromMap).toList();
  }

  Future<List<ElogEntry>> listEntriesByIds(List<String> entryIds) async {
    if (entryIds.isEmpty) return [];
    final quoted = entryIds.toSet().map((id) => '"$id"').join(',');
    final response = await _client
        .from('elog_entries')
        .select('*')
        .filter('id', 'in', '($quoted)')
        .order('updated_at', ascending: false);
    final rows = (response as List).cast<Map<String, dynamic>>();
    return rows.map(ElogEntry.fromMap).toList();
  }

  Future<List<ElogEntry>> listEntriesReviewedBy(String reviewerId) async {
    final response = await _client
        .from('elog_entries')
        .select('*')
        .eq('reviewed_by', reviewerId)
        .order('updated_at', ascending: false);
    final rows = (response as List).cast<Map<String, dynamic>>();
    return rows.map(ElogEntry.fromMap).toList();
  }
}

final entriesRepositoryProvider = Provider<EntriesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return EntriesRepository(client);
});
