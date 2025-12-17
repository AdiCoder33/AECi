import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';
import '../../logbook/domain/elog_entry.dart';

class QualityRepository {
  QualityRepository(this._client);
  final SupabaseClient _client;

  Future<void> scoreEntry(String entryId) async {
    final res = await _client.functions.invoke('score-entry', body: {
      'entryId': entryId,
    });
    if (res.status >= 400) {
      throw res.data ?? 'Failed to score entry';
    }
  }

  Future<List<ElogEntry>> similarEntries(ElogEntry entry) async {
    final rows = await _client
        .from('elog_entries')
        .select('*')
        .eq('module_type', entry.moduleType)
        .neq('id', entry.id)
        .limit(50);
    final list = (rows as List)
        .map((e) => ElogEntry.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    final kwSet = entry.keywords.toSet();
    list.sort((a, b) {
      final overlapA = a.keywords.where(kwSet.contains).length;
      final overlapB = b.keywords.where(kwSet.contains).length;
      return overlapB.compareTo(overlapA);
    });
    return list.take(5).toList();
  }
}

final qualityRepositoryProvider = Provider<QualityRepository>((ref) {
  return QualityRepository(ref.watch(supabaseClientProvider));
});
