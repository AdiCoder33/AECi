import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';
import '../../logbook/domain/elog_entry.dart';

class TeachingItem {
  TeachingItem({
    required this.id,
    required this.title,
    required this.moduleType,
    required this.shareScope,
    required this.keywords,
    required this.redactedPayload,
    required this.mediaPaths,
  });

  final String id;
  final String title;
  final String moduleType;
  final String shareScope;
  final List<String> keywords;
  final Map<String, dynamic> redactedPayload;
  final List<String> mediaPaths;

  factory TeachingItem.fromMap(Map<String, dynamic> map) => TeachingItem(
        id: map['id'] as String,
        title: map['title'] as String,
        moduleType: map['module_type'] as String,
        shareScope: map['share_scope'] as String,
        keywords: (map['keywords'] as List).cast<String>(),
        redactedPayload: Map<String, dynamic>.from(map['redacted_payload'] as Map),
        mediaPaths: (map['media_paths'] as List?)?.cast<String>() ?? const [],
      );
}

class TeachingProposal {
  TeachingProposal({
    required this.id,
    required this.entryId,
    required this.status,
    this.note,
  });
  final String id;
  final String entryId;
  final String status;
  final String? note;

  factory TeachingProposal.fromMap(Map<String, dynamic> map) => TeachingProposal(
        id: map['id'] as String,
        entryId: map['entry_id'] as String,
        status: map['status'] as String,
        note: map['note'] as String?,
      );
}

class TeachingRepository {
  TeachingRepository(this._client);
  final SupabaseClient _client;

  Future<void> propose(String entryId, String note) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw AuthException('Not signed in');
    await _client.from('teaching_item_proposals').insert({
      'entry_id': entryId,
      'proposed_by': uid,
      'note': note,
    });
  }

  Future<List<TeachingProposal>> listProposals() async {
    final rows = await _client
        .from('teaching_item_proposals')
        .select('*')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => TeachingProposal.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> reviewProposal(String id, String decision) async {
    final uid = _client.auth.currentUser?.id;
    await _client.from('teaching_item_proposals').update({
      'status': decision,
      'reviewed_by': uid,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<String> publishFromEntry({
    required ElogEntry entry,
    required String title,
    required String summary,
    required String shareScope,
    required String centre,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw AuthException('Not signed in');
    final redacted = Map<String, dynamic>.from(entry.payload);
    redacted.remove('mrn');
    redacted.remove('patientUniqueId');
    final inserted = await _client
        .from('teaching_items')
        .insert({
          'source_entry_id': entry.id,
          'created_by': uid,
          'centre': centre,
          'module_type': entry.moduleType,
          'title': title,
          'teaching_summary': summary,
          'redacted_payload': redacted,
          'media_paths': [],
          'keywords': entry.keywords,
          'share_scope': shareScope,
        })
        .select('id')
        .maybeSingle();
    if (inserted == null) throw PostgrestException(message: 'Publish failed');
    return inserted['id'] as String;
  }

  Future<List<TeachingItem>> listTeaching({
    String? module,
    String? scope,
    String? centre,
    String? keyword,
  }) async {
    PostgrestFilterBuilder<dynamic> query =
        _client.from('teaching_items').select('*');
    if (module != null) query = query.eq('module_type', module);
    if (scope != null) query = query.eq('share_scope', scope);
    if (centre != null) query = query.eq('centre', centre);
    final rows = await query.order('updated_at', ascending: false);
    var list = (rows as List)
        .map((e) => TeachingItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    if (keyword != null && keyword.isNotEmpty) {
      final lower = keyword.toLowerCase();
      list = list.where((t) => t.keywords.any((k) => k.toLowerCase().contains(lower))).toList();
    }
    return list;
  }

  Future<void> toggleBookmark(String itemId, bool add) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw AuthException('Not signed in');
    if (add) {
      await _client.from('teaching_item_bookmarks').upsert({
        'teaching_item_id': itemId,
        'user_id': uid,
      });
    } else {
      await _client
          .from('teaching_item_bookmarks')
          .delete()
          .eq('teaching_item_id', itemId)
          .eq('user_id', uid);
    }
  }
}

final teachingRepositoryProvider = Provider<TeachingRepository>((ref) {
  return TeachingRepository(ref.watch(supabaseClientProvider));
});
