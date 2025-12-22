import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    return inserted?['id'] as String;
  }

  Future<void> consultantUpdate({
    required String assessmentId,
    required String status,
    String? comments,
  }) async {
    await _client.from('case_assessments').update({
      'status': status,
      'consultant_comments': comments,
      'assessed_at': status == 'completed' ? DateTime.now().toIso8601String() : null,
    }).eq('id', assessmentId);
  }

  Future<List<CaseAssessment>> listAssigned(String consultantId) async {
    final rows = await _client
        .from('case_assessments')
        .select('*, clinical_cases(id, patient_name, uid_number, mr_number)')
        .eq('assigned_consultant_id', consultantId)
        .eq('status', 'submitted');
    return (rows as List)
        .map((e) => CaseAssessment.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }
}

final assessmentRepositoryProvider = Provider<AssessmentRepository>((ref) {
  return AssessmentRepository(ref.watch(supabaseClientProvider));
});
