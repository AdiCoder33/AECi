import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';

class ClinicalCase {
  ClinicalCase({
    required this.id,
    required this.createdBy,
    required this.dateOfExamination,
    required this.patientName,
    required this.uidNumber,
    required this.mrNumber,
    required this.patientGender,
    required this.patientAge,
    required this.chiefComplaint,
    required this.complaintDurationValue,
    required this.complaintDurationUnit,
    required this.systemicHistory,
    required this.keywords,
    required this.diagnosis,
    this.diagnosisOther,
    this.management,
    this.learningPoint,
    this.updatedAt,
  });

  final String id;
  final String createdBy;
  final DateTime dateOfExamination;
  final String patientName;
  final String uidNumber;
  final String mrNumber;
  final String patientGender;
  final int patientAge;
  final String chiefComplaint;
  final int complaintDurationValue;
  final String complaintDurationUnit;
  final List<dynamic> systemicHistory;
  final List<String> keywords;
  final String diagnosis;
  final String? diagnosisOther;
  final String? management;
  final String? learningPoint;
  final DateTime? updatedAt;

  factory ClinicalCase.fromMap(Map<String, dynamic> map) => ClinicalCase(
        id: map['id'] as String,
        createdBy: map['created_by'] as String,
        dateOfExamination: DateTime.parse(map['date_of_examination'] as String),
        patientName: map['patient_name'] as String,
        uidNumber: map['uid_number'] as String,
        mrNumber: map['mr_number'] as String,
        patientGender: map['patient_gender'] as String,
        patientAge: map['patient_age'] as int,
        chiefComplaint: map['chief_complaint'] as String,
        complaintDurationValue: map['complaint_duration_value'] as int,
        complaintDurationUnit: map['complaint_duration_unit'] as String,
        systemicHistory: (map['systemic_history'] as List?) ?? const [],
        keywords: (map['keywords'] as List).cast<String>(),
        diagnosis: map['diagnosis'] as String,
        diagnosisOther: map['diagnosis_other'] as String?,
        management: map['management'] as String?,
        learningPoint: map['learning_point'] as String?,
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'] as String)
            : null,
      );
}

class CaseFollowup {
  CaseFollowup({
    required this.id,
    required this.caseId,
    required this.followupIndex,
    required this.dateOfExamination,
    required this.intervalDays,
    this.anteriorSegmentFindings,
    this.fundusFindings,
  });

  final String id;
  final String caseId;
  final int followupIndex;
  final DateTime dateOfExamination;
  final int intervalDays;
  final String? anteriorSegmentFindings;
  final String? fundusFindings;

  factory CaseFollowup.fromMap(Map<String, dynamic> map) => CaseFollowup(
        id: map['id'] as String,
        caseId: map['case_id'] as String,
        followupIndex: map['followup_index'] as int,
        dateOfExamination: DateTime.parse(map['date_of_examination'] as String),
        intervalDays: map['interval_days'] as int,
        anteriorSegmentFindings: map['anterior_segment_findings'] as String?,
        fundusFindings: map['fundus_findings'] as String?,
      );
}

class CaseMediaItem {
  CaseMediaItem({
    required this.id,
    required this.caseId,
    this.followupId,
    required this.category,
    required this.mediaType,
    required this.storagePath,
    this.note,
  });
  final String id;
  final String caseId;
  final String? followupId;
  final String category;
  final String mediaType;
  final String storagePath;
  final String? note;

  factory CaseMediaItem.fromMap(Map<String, dynamic> map) => CaseMediaItem(
        id: map['id'] as String,
        caseId: map['case_id'] as String,
        followupId: map['followup_id'] as String?,
        category: map['category'] as String,
        mediaType: map['media_type'] as String,
        storagePath: map['storage_path'] as String,
        note: map['note'] as String?,
      );
}

class ClinicalCasesRepository {
  ClinicalCasesRepository(this._client);
  final SupabaseClient _client;

  Future<List<ClinicalCase>> listCases() async {
    final rows = await _client
        .from('clinical_cases')
        .select('*')
        .order('updated_at', ascending: false);
    return (rows as List)
        .map((e) => ClinicalCase.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ClinicalCase> getCase(String id) async {
    final row = await _client
        .from('clinical_cases')
        .select('*')
        .eq('id', id)
        .maybeSingle();
    if (row == null) {
      throw PostgrestException(message: 'Not found');
    }
    return ClinicalCase.fromMap(Map<String, dynamic>.from(row));
  }

  Future<String> createCase(Map<String, dynamic> data) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw AuthException('Not signed in');
    data['created_by'] = uid;
    final inserted =
        await _client.from('clinical_cases').insert(data).select('id').maybeSingle();
    if (inserted == null) throw PostgrestException(message: 'Create failed');
    return inserted['id'] as String;
  }

  Future<void> updateCase(String id, Map<String, dynamic> data) async {
    await _client.from('clinical_cases').update(data).eq('id', id);
  }

  Future<void> addFollowup(String caseId, Map<String, dynamic> data) async {
    data['case_id'] = caseId;
    await _client.from('case_followups').insert(data);
  }

  Future<List<CaseFollowup>> listFollowups(String caseId) async {
    final rows = await _client
        .from('case_followups')
        .select('*')
        .eq('case_id', caseId)
        .order('followup_index', ascending: true);
    return (rows as List)
        .map((e) => CaseFollowup.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<CaseMediaItem>> listMedia(String caseId) async {
    final rows =
        await _client.from('case_media').select('*').eq('case_id', caseId);
    return (rows as List)
        .map((e) => CaseMediaItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<String> uploadMedia({
    required String caseId,
    String? followupId,
    required String category,
    required String mediaType,
    required File file,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw AuthException('Not signed in');
    final path = followupId == null
        ? '$uid/cases/$caseId/${p.basename(file.path)}'
        : '$uid/cases/$caseId/followups/$followupId/${p.basename(file.path)}';
    await _client.storage.from('elogbook-media').upload(path, file);
    await _client.from('case_media').insert({
      'case_id': caseId,
      'followup_id': followupId,
      'category': category,
      'media_type': mediaType,
      'storage_path': path,
    });
    return path;
  }
}

final clinicalCasesRepositoryProvider =
    Provider<ClinicalCasesRepository>((ref) {
  return ClinicalCasesRepository(ref.watch(supabaseClientProvider));
});
