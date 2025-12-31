import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';

class ReviewItem {
  ReviewItem({
    required this.entityType,
    required this.entityId,
    required this.traineeId,
    required this.title,
    required this.subtitle,
    required this.updatedAt,
    this.videoLink,
  });

  final String entityType;
  final String entityId;
  final String traineeId;
  final String title;
  final String subtitle;
  final DateTime updatedAt;
  final String? videoLink;
}

class ReviewedItem {
  ReviewedItem({
    required this.entityType,
    required this.entityId,
    required this.traineeId,
    required this.title,
    required this.subtitle,
    required this.score,
    required this.remarks,
    required this.updatedAt,
  });

  final String entityType;
  final String entityId;
  final String traineeId;
  final String title;
  final String subtitle;
  final int? score;
  final String? remarks;
  final DateTime updatedAt;
}

class ReviewerAssessment {
  ReviewerAssessment({
    required this.id,
    required this.reviewerId,
    required this.traineeId,
    required this.entityType,
    required this.entityId,
    this.score,
    this.remarks,
    this.oscarScores,
    this.oscarTotal,
    required this.updatedAt,
  });

  final String id;
  final String reviewerId;
  final String traineeId;
  final String entityType;
  final String entityId;
  final int? score;
  final String? remarks;
  final List<dynamic>? oscarScores;
  final int? oscarTotal;
  final DateTime updatedAt;

  factory ReviewerAssessment.fromMap(Map<String, dynamic> map) {
    return ReviewerAssessment(
      id: map['id'] as String,
      reviewerId: map['reviewer_id'] as String,
      traineeId: map['trainee_id'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      score: map['score'] as int?,
      remarks: map['remarks'] as String?,
      oscarScores: map['oscar_scores'] as List?,
      oscarTotal: map['oscar_total'] as int?,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class ReviewerRepository {
  ReviewerRepository(this._client);

  final SupabaseClient _client;

  Future<List<String>> listAssignedTrainees() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _client
        .from('reviewer_assignments')
        .select('trainee_id')
        .eq('reviewer_id', uid);
    return (rows as List)
        .map((e) => (e as Map)['trainee_id'] as String)
        .toList();
  }

  Future<List<ReviewerAssessment>> listMyAssessments() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _client
        .from('reviewer_assessments')
        .select('*')
        .eq('reviewer_id', uid)
        .order('updated_at', ascending: false);
    return (rows as List)
        .map((e) => ReviewerAssessment.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<ReviewItem>> listPendingItems({int sinceDays = 90}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final traineeIds = await listAssignedTrainees();
    if (traineeIds.isEmpty) return [];
    final since = DateTime.now().subtract(Duration(days: sinceDays));
    final assessed = await listMyAssessments();
    final assessedKey = assessed
        .map((a) => '${a.entityType}:${a.entityId}')
        .toSet();

    final quotedTrainees = traineeIds.map((id) => '"$id"').join(',');
    final caseRows = await _client
        .from('clinical_cases')
        .select(
          'id, created_by, patient_name, uid_number, mr_number, diagnosis, updated_at',
        )
        .eq('status', 'submitted')
        .gte('created_at', since.toIso8601String())
        .filter('created_by', 'in', '($quotedTrainees)');
    final caseItems = (caseRows as List)
        .map((row) => Map<String, dynamic>.from(row))
        .where((row) => !assessedKey.contains('clinical_case:${row['id']}'))
        .map((row) {
      final updatedAt = row['updated_at'] as String?;
      return ReviewItem(
        entityType: 'clinical_case',
        entityId: row['id'] as String,
        traineeId: row['created_by'] as String,
        title: row['patient_name'] as String,
        subtitle: 'UID ${row['uid_number']} | MR ${row['mr_number']}',
        updatedAt: updatedAt == null
            ? DateTime.now()
            : DateTime.parse(updatedAt),
      );
    }).toList();

    final entryRows = await _client
        .from('elog_entries')
        .select(
          'id, created_by, patient_unique_id, mrn, module_type, payload, updated_at',
        )
        .eq('status', 'submitted')
        .gte('created_at', since.toIso8601String())
        .filter('created_by', 'in', '($quotedTrainees)')
        .filter('module_type', 'in', '("learning","records")');
    final entryItems = (entryRows as List)
        .map((row) => Map<String, dynamic>.from(row))
        .where((row) => !assessedKey.contains('elog_entry:${row['id']}'))
        .where((row) {
      final payload = Map<String, dynamic>.from(row['payload'] as Map);
      final link = (payload['surgicalVideoLink'] as String?) ?? '';
      return link.trim().isNotEmpty;
    })
        .map((row) {
      final payload = Map<String, dynamic>.from(row['payload'] as Map);
      final link = (payload['surgicalVideoLink'] as String?) ?? '';
      final updatedAt = row['updated_at'] as String?;
      return ReviewItem(
        entityType: 'elog_entry',
        entityId: row['id'] as String,
        traineeId: row['created_by'] as String,
        title: 'Surgical Video (${row['module_type']})',
        subtitle: 'Patient ${row['patient_unique_id']} | MR ${row['mrn']}',
        updatedAt: updatedAt == null
            ? DateTime.now()
            : DateTime.parse(updatedAt),
        videoLink: link.trim().isEmpty ? null : link.trim(),
      );
    }).toList();

    final combined = [...caseItems, ...entryItems];
    combined.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return combined;
  }

  Future<List<ReviewedItem>> listReviewedItems() async {
    final assessments = await listMyAssessments();
    if (assessments.isEmpty) return [];
    final caseIds = assessments
        .where((a) => a.entityType == 'clinical_case')
        .map((a) => a.entityId)
        .toList();
    final entryIds = assessments
        .where((a) => a.entityType == 'elog_entry')
        .map((a) => a.entityId)
        .toList();

    final caseMap = <String, Map<String, dynamic>>{};
    if (caseIds.isNotEmpty) {
      final quoted = caseIds.map((id) => '"$id"').join(',');
      final rows = await _client
          .from('clinical_cases')
          .select('id, patient_name, uid_number, mr_number')
          .filter('id', 'in', '($quoted)');
      for (final row in rows as List) {
        final data = Map<String, dynamic>.from(row);
        caseMap[data['id'] as String] = data;
      }
    }

    final entryMap = <String, Map<String, dynamic>>{};
    if (entryIds.isNotEmpty) {
      final quoted = entryIds.map((id) => '"$id"').join(',');
      final rows = await _client
          .from('elog_entries')
          .select('id, patient_unique_id, mrn, module_type')
          .filter('id', 'in', '($quoted)');
      for (final row in rows as List) {
        final data = Map<String, dynamic>.from(row);
        entryMap[data['id'] as String] = data;
      }
    }

    return assessments.map((assessment) {
      if (assessment.entityType == 'clinical_case') {
        final caseData = caseMap[assessment.entityId];
        return ReviewedItem(
          entityType: assessment.entityType,
          entityId: assessment.entityId,
          traineeId: assessment.traineeId,
          title: caseData?['patient_name'] as String? ?? 'Clinical case',
          subtitle: caseData == null
              ? 'Case ${assessment.entityId}'
              : 'UID ${caseData['uid_number']} | MR ${caseData['mr_number']}',
          score: assessment.score,
          remarks: assessment.remarks,
          updatedAt: assessment.updatedAt,
        );
      }
      final entryData = entryMap[assessment.entityId];
      return ReviewedItem(
        entityType: assessment.entityType,
        entityId: assessment.entityId,
        traineeId: assessment.traineeId,
        title: 'Surgical Video (${entryData?['module_type'] ?? 'logbook'})',
        subtitle: entryData == null
            ? 'Entry ${assessment.entityId}'
            : 'Patient ${entryData['patient_unique_id']} | MR ${entryData['mrn']}',
        score: assessment.oscarTotal,
        remarks: assessment.remarks,
        updatedAt: assessment.updatedAt,
      );
    }).toList();
  }

  Future<void> submitClinicalCaseReview({
    required String caseId,
    required String traineeId,
    required int score,
    required String remarks,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw AuthException('Not signed in');
    await _client.from('reviewer_assessments').upsert({
      'reviewer_id': uid,
      'trainee_id': traineeId,
      'entity_type': 'clinical_case',
      'entity_id': caseId,
      'score': score,
      'remarks': remarks,
      'status': 'completed',
    });
  }

  Future<void> submitSurgicalVideoReview({
    required String entryId,
    required String traineeId,
    required List<Map<String, dynamic>> oscarScores,
    required int totalScore,
    required String remarks,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw AuthException('Not signed in');
    await _client.from('reviewer_assessments').upsert({
      'reviewer_id': uid,
      'trainee_id': traineeId,
      'entity_type': 'elog_entry',
      'entity_id': entryId,
      'oscar_scores': oscarScores,
      'oscar_total': totalScore,
      'remarks': remarks,
      'status': 'completed',
    });
  }
}

final reviewerRepositoryProvider = Provider<ReviewerRepository>((ref) {
  return ReviewerRepository(ref.watch(supabaseClientProvider));
});
