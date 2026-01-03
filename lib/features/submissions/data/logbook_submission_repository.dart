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

class LogbookSubmission {
  LogbookSubmission({
    required this.id,
    required this.createdBy,
    required this.moduleKeys,
    required this.createdAt,
  });

  final String id;
  final String createdBy;
  final List<String> moduleKeys;
  final DateTime createdAt;

  factory LogbookSubmission.fromMap(Map<String, dynamic> map) {
    return LogbookSubmission(
      id: map['id'] as String,
      createdBy: map['created_by'] as String,
      moduleKeys: (map['module_keys'] as List).cast<String>(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class LogbookSubmissionItemRecord {
  LogbookSubmissionItemRecord({
    required this.submissionId,
    required this.moduleKey,
    required this.entityType,
    required this.entityId,
    required this.createdAt,
  });

  final String submissionId;
  final String moduleKey;
  final String entityType;
  final String entityId;
  final DateTime createdAt;

  factory LogbookSubmissionItemRecord.fromMap(Map<String, dynamic> map) {
    return LogbookSubmissionItemRecord(
      submissionId: map['submission_id'] as String,
      moduleKey: map['module_key'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class LogbookSubmissionRepository {
  LogbookSubmissionRepository(this._client);

  final SupabaseClient _client;

  Future<List<LogbookSubmission>> listSubmissionsForRecipient({
    String? recipientId,
  }) async {
    final uid = recipientId ?? _client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _client
        .from('logbook_submission_recipients')
        .select(
          'submission_id, logbook_submissions:submission_id(id, created_by, module_keys, created_at)',
        )
        .eq('recipient_id', uid)
        .order('created_at', ascending: false);
    final submissions = <LogbookSubmission>[];
    for (final row in rows as List) {
      final data = Map<String, dynamic>.from(row);
      final rawSubmission = data['logbook_submissions'];
      if (rawSubmission == null) continue;
      final submission = Map<String, dynamic>.from(rawSubmission as Map);
      submissions.add(LogbookSubmission.fromMap(submission));
    }
    return submissions;
  }

  Future<List<LogbookSubmissionItemRecord>> listSubmissionItems(
    List<String> submissionIds,
  ) async {
    if (submissionIds.isEmpty) return [];
    final quoted = submissionIds.toSet().map((id) => '"$id"').join(',');
    final rows = await _client
        .from('logbook_submission_items')
        .select('*')
        .filter('submission_id', 'in', '($quoted)')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) =>
            LogbookSubmissionItemRecord.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

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
