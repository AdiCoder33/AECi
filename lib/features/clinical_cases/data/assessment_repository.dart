import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart';

import '../../../core/supabase_client.dart';

class CaseAssessment {
  CaseAssessment({
    required this.id,
    required this.caseId,
    required this.submittedBy,
    required this.assignedConsultantId,
    required this.status,
    this.consultantComments,
    this.assessedAt,
  });

  final String id;
  final String caseId;
  final String submittedBy;
  final String assignedConsultantId;
  final String status;
  final String? consultantComments;
  final DateTime? assessedAt;

  factory CaseAssessment.fromMap(Map<String, dynamic> map) => CaseAssessment(
        id: map['id'] as String,
        caseId: map['case_id'] as String,
        submittedBy: map['submitted_by'] as String,
        assignedConsultantId: map['assigned_consultant_id'] as String,
        status: map['status'] as String,
        consultantComments: map['consultant_comments'] as String?,
        assessedAt: map['assessed_at'] != null
            ? DateTime.parse(map['assessed_at'] as String)
            : null,
      );
}

class AssessmentRecipient {
  AssessmentRecipient({
    required this.recipientId,
    required this.name,
    required this.designation,
    required this.centre,
    required this.canReview,
  });

  final String recipientId;
  final String name;
  final String designation;
  final String centre;
  final bool canReview;
}

class RosterConsultant {
  RosterConsultant({
    required this.id,
    required this.name,
    required this.designation,
    required this.centre,
  });

  final String id;
  final String name;
  final String designation;
  final String centre;
}

class AssessmentQueueItem {
  AssessmentQueueItem({
    required this.assessmentId,
    required this.caseId,
    required this.patientName,
    required this.uidNumber,
    required this.mrNumber,
    required this.status,
  });

  final String assessmentId;
  final String caseId;
  final String patientName;
  final String uidNumber;
  final String mrNumber;
  final String status;
}

class AssessmentRepository {
  AssessmentRepository(this._client);
  final SupabaseClient _client;

  Future<CaseAssessment?> getAssessment(String caseId) async {
    final row = await _client
        .from('case_assessments')
        .select('*')
        .eq('case_id', caseId)
        .maybeSingle();
    if (row == null) return null;
    return CaseAssessment.fromMap(Map<String, dynamic>.from(row));
  }

  Future<List<AssessmentRecipient>> listRecipients(String caseId) async {
    final rows = await _client
        .from('case_assessment_recipients')
        .select('recipient_id, can_review')
        .eq('case_id', caseId)
        .order('created_at');
    final recipients = (rows as List)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    final ids = recipients
        .map((row) => row['recipient_id'] as String)
        .toList();
    if (ids.isEmpty) return [];

    final quoted = ids.map((id) => '"$id"').join(',');
    final profiles = await _client
        .from('profiles')
        .select('id, name, designation, centre, aravind_centre')
        .filter('id', 'in', '($quoted)');
    final byId = {
      for (final row in profiles as List)
        (row as Map)['id'] as String: row
    };

    return recipients.map((row) {
      final profile = Map<String, dynamic>.from(
        byId[row['recipient_id']] as Map? ?? {},
      );
      return AssessmentRecipient(
        recipientId: row['recipient_id'] as String,
        name: (profile['name'] as String?) ?? 'Unknown',
        designation: (profile['designation'] as String?) ?? 'Doctor',
        centre: (profile['aravind_centre'] as String?) ??
            (profile['centre'] as String?) ??
            '',
        canReview: (row['can_review'] as bool?) ?? false,
      );
    }).toList();
  }

  Future<void> submitRecipients({
    required String caseId,
    required List<String> recipientIds,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw AuthException('Not signed in');
    if (recipientIds.isEmpty) {
      throw PostgrestException(message: 'Select at least one doctor');
    }

    await _client.from('case_assessment_recipients').delete().eq(
          'case_id',
          caseId,
        );

    final quotedIds = recipientIds.map((id) => '"$id"').join(',');
    final profiles = await _client
        .from('profiles')
        .select('id, name, designation')
        .filter('id', 'in', '($quotedIds)');
    final byId = {
      for (final row in profiles as List)
        (row as Map)['id'] as String: row
    };

    final inserts = recipientIds.map((id) {
      final profile = Map<String, dynamic>.from(byId[id] as Map? ?? {});
      final designation = (profile['designation'] as String?) ?? '';
      return {
        'case_id': caseId,
        'recipient_id': id,
        'can_review': designation == 'Reviewer',
      };
    }).toList();

    await _client.from('case_assessment_recipients').insert(inserts);
    await _client
        .from('clinical_cases')
        .update({'status': 'submitted'}).eq('id', caseId);

    final caseRow = await _client
        .from('clinical_cases')
        .select('patient_name, uid_number')
        .eq('id', caseId)
        .maybeSingle();
    final title = 'New case submitted';
    final body = caseRow == null
        ? 'A clinical case was submitted for assessment.'
        : '${caseRow['patient_name']} (UID ${caseRow['uid_number']})';
    for (final id in recipientIds) {
      await _client.rpc('notify_user', params: {
        'p_user_id': id,
        'p_type': 'case_submitted',
        'p_title': title,
        'p_body': body,
        'p_entity_type': 'clinical_case',
        'p_entity_id': caseId,
      });
    }
  }

  Future<String> submitForAssessment({
    required String caseId,
    required String consultantId,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw AuthException('Not signed in');
    final inserted = await _client.from('case_assessments').upsert({
      'case_id': caseId,
      'submitted_by': uid,
      'assigned_consultant_id': consultantId,
      'status': 'submitted',
    }).select('id').maybeSingle();
    if (inserted == null) {
      throw PostgrestException(message: 'Unable to submit assessment');
    }
    await _client
        .from('clinical_cases')
        .update({'status': 'submitted'}).eq('id', caseId);
    final caseRow = await _client
        .from('clinical_cases')
        .select('patient_name, uid_number, mr_number')
        .eq('id', caseId)
        .maybeSingle();
    final title = 'New case submitted';
    final body = caseRow == null
        ? 'A clinical case was submitted for review.'
        : '${caseRow['patient_name']} (UID ${caseRow['uid_number']})';
    await _client.rpc('notify_user', params: {
      'p_user_id': consultantId,
      'p_type': 'case_submitted',
      'p_title': title,
      'p_body': body,
      'p_entity_type': 'clinical_case',
      'p_entity_id': caseId,
    });
    return inserted['id'] as String;
  }

  Future<void> consultantUpdate({
    required String assessmentId,
    required String status,
    String? comments,
  }) async {
    final row = await _client.from('case_assessments').update({
      'status': status,
      'consultant_comments': comments,
      'assessed_at': status == 'completed' ? DateTime.now().toIso8601String() : null,
    }).eq('id', assessmentId).select('submitted_by, case_id').maybeSingle();
    if (status == 'completed' && row != null) {
      await _client.rpc('notify_user', params: {
        'p_user_id': row['submitted_by'],
        'p_type': 'assessment_completed',
        'p_title': 'Assessment completed',
        'p_body': 'Your clinical case assessment is complete.',
        'p_entity_type': 'clinical_case',
        'p_entity_id': row['case_id'],
      });
    }
  }

  Future<List<AssessmentQueueItem>> listAssignedQueue(String consultantId) async {
    final rows = await _client
        .from('case_assessments')
        .select('id, case_id, status, clinical_cases:case_id(patient_name, uid_number, mr_number)')
        .eq('assigned_consultant_id', consultantId)
        .eq('status', 'submitted')
        .order('created_at');
    return (rows as List).map((e) {
      final map = Map<String, dynamic>.from(e);
      final caseMap = Map<String, dynamic>.from(map['clinical_cases'] as Map);
      return AssessmentQueueItem(
        assessmentId: map['id'] as String,
        caseId: map['case_id'] as String,
        patientName: caseMap['patient_name'] as String,
        uidNumber: caseMap['uid_number'] as String,
        mrNumber: caseMap['mr_number'] as String,
        status: map['status'] as String,
      );
    }).toList();
  }

  Future<List<RosterConsultant>> listRoster({
    required String centre,
    required String monthKey,
  }) async {
    final rows = await _client
        .from('assessment_roster')
        .select('consultant_id')
        .eq('centre', centre)
        .eq('month_key', monthKey)
        .eq('is_active', true);
    final ids = (rows as List)
        .map((e) => (e as Map)['consultant_id'] as String)
        .toList();
    if (ids.isEmpty) return [];
    final quotedIds = ids.map((id) => '"$id"').join(',');
    final profiles = await _client
        .from('profiles')
        .select('id, name, designation, centre')
        .filter('id', 'in', '($quotedIds)');
    final byId = {
      for (final row in profiles as List)
        (row as Map)['id'] as String: row
    };
    return ids
        .where((id) => byId.containsKey(id))
        .map((id) {
          final row = Map<String, dynamic>.from(byId[id] as Map);
          return RosterConsultant(
            id: row['id'] as String,
            name: row['name'] as String,
            designation: row['designation'] as String,
            centre: row['centre'] as String,
          );
        })
        .toList();
  }
}

final assessmentRepositoryProvider = Provider<AssessmentRepository>((ref) {
  return AssessmentRepository(ref.watch(supabaseClientProvider));
});
