import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';
import '../../logbook/domain/logbook_sections.dart';

class LogbookSubmissionItem {
  LogbookSubmissionItem({
    required this.moduleKey,
    required this.entityType,
    required this.entityId,
  });

  final String moduleKey;
  final String entityType;
  final String entityId;
}

class LogbookSubmissionRepository {
  LogbookSubmissionRepository(this._client);

  final SupabaseClient _client;

  Future<String> submit({
    required List<String> moduleKeys,
    required List<String> recipientIds,
    required List<LogbookSubmissionItem> items,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw AuthException('Not signed in');
    if (moduleKeys.isEmpty) {
      throw PostgrestException(message: 'Select at least one section');
    }
    if (items.isEmpty) {
      throw PostgrestException(message: 'Select at least one item');
    }
    if (recipientIds.isEmpty) {
      throw PostgrestException(message: 'Select at least one doctor');
    }

    final inserted = await _client.from('logbook_submissions').insert({
      'created_by': uid,
      'module_keys': moduleKeys,
    }).select('id').maybeSingle();
    if (inserted == null) {
      throw PostgrestException(message: 'Submission failed');
    }
    final submissionId = inserted['id'] as String;

    final itemRows = items
        .map(
          (item) => {
            'submission_id': submissionId,
            'module_key': item.moduleKey,
            'entity_type': item.entityType,
            'entity_id': item.entityId,
          },
        )
        .toList();
    await _client.from('logbook_submission_items').insert(itemRows);

    final recipients = recipientIds
        .map((id) => {'submission_id': submissionId, 'recipient_id': id})
        .toList();
    await _client.from('logbook_submission_recipients').insert(recipients);

    final labels = moduleKeys
        .map((key) => logbookSections.firstWhere((s) => s.key == key).label)
        .toList();
    final title = 'New logbook submission';
    final body = 'Shared: ${labels.join(', ')}';

    for (final id in recipientIds) {
      await _client.rpc('notify_user', params: {
        'p_user_id': id,
        'p_type': 'logbook_submitted',
        'p_title': title,
        'p_body': body,
        'p_entity_type': 'logbook_submission',
        'p_entity_id': submissionId,
      });
    }

    return submissionId;
  }
}

final logbookSubmissionRepositoryProvider =
    Provider<LogbookSubmissionRepository>((ref) {
  return LogbookSubmissionRepository(ref.watch(supabaseClientProvider));
});
