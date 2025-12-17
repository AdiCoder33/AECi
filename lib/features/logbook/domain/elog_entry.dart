import 'dart:convert';

class ElogEntry {
  const ElogEntry({
    required this.id,
    required this.moduleType,
    required this.createdBy,
    required this.patientUniqueId,
    required this.mrn,
    required this.keywords,
    required this.status,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
    this.authorProfile,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewComment,
    this.requiredChanges = const [],
    this.reviewerProfile,
    this.qualityScore,
    this.qualityIssues = const [],
  });

  final String id;
  final String moduleType;
  final String createdBy;
  final String patientUniqueId;
  final String mrn;
  final List<String> keywords;
  final String status;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? authorProfile;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewComment;
  final List<dynamic> requiredChanges;
  final Map<String, dynamic>? reviewerProfile;
  final int? qualityScore;
  final List<dynamic> qualityIssues;

  factory ElogEntry.fromMap(Map<String, dynamic> map) {
    return ElogEntry(
      id: map['id'] as String,
      moduleType: map['module_type'] as String,
      createdBy: map['created_by'] as String,
      patientUniqueId: map['patient_unique_id'] as String,
      mrn: map['mrn'] as String,
      keywords: (map['keywords'] as List).cast<String>(),
      status: map['status'] as String,
      payload: Map<String, dynamic>.from(map['payload'] as Map),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      authorProfile: map['profiles'] != null
          ? Map<String, dynamic>.from(map['profiles'] as Map)
          : map['author_profile'] != null
              ? Map<String, dynamic>.from(map['author_profile'] as Map)
              : null,
      reviewerProfile: map['reviewer_profile'] == null
          ? null
          : Map<String, dynamic>.from(map['reviewer_profile'] as Map),
      submittedAt: map['submitted_at'] != null
          ? DateTime.parse(map['submitted_at'] as String)
          : null,
      reviewedAt: map['reviewed_at'] != null
          ? DateTime.parse(map['reviewed_at'] as String)
          : null,
      reviewedBy: map['reviewed_by'] as String?,
      reviewComment: map['review_comment'] as String?,
      requiredChanges:
          (map['required_changes'] as List?)?.toList() ?? const [],
      qualityScore: map['quality_score'] as int?,
      qualityIssues: (map['quality_issues'] as List?)?.toList() ?? const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module_type': moduleType,
      'created_by': createdBy,
      'patient_unique_id': patientUniqueId,
      'mrn': mrn,
      'keywords': keywords,
      'status': status,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ElogEntryCreate {
  const ElogEntryCreate({
    required this.moduleType,
    required this.patientUniqueId,
    required this.mrn,
    required this.keywords,
    required this.payload,
  });

  final String moduleType;
  final String patientUniqueId;
  final String mrn;
  final List<String> keywords;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toInsertMap(String userId) {
    return {
      'module_type': moduleType,
      'patient_unique_id': patientUniqueId,
      'mrn': mrn,
      'keywords': keywords,
      'payload': jsonDecode(jsonEncode(payload)),
      'status': 'draft',
      'created_by': userId,
    };
  }
}

class ElogEntryUpdate {
  const ElogEntryUpdate({
    this.patientUniqueId,
    this.mrn,
    this.keywords,
    this.payload,
    this.status,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewComment,
    this.requiredChanges,
    this.clearReview = false,
  });

  final String? patientUniqueId;
  final String? mrn;
  final List<String>? keywords;
  final Map<String, dynamic>? payload;
  final String? status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewComment;
  final List<String>? requiredChanges;
  // when true, reviewed_by/review_comment/required_changes are nulled/reset
  final bool clearReview;

  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{
      if (patientUniqueId != null) 'patient_unique_id': patientUniqueId,
      if (mrn != null) 'mrn': mrn,
      if (keywords != null) 'keywords': keywords,
      if (payload != null) 'payload': jsonDecode(jsonEncode(payload)),
      if (status != null) 'status': status,
      if (submittedAt != null) 'submitted_at': submittedAt!.toIso8601String(),
      if (reviewedAt != null) 'reviewed_at': reviewedAt!.toIso8601String(),
      if (reviewedBy != null) 'reviewed_by': reviewedBy,
      if (reviewComment != null) 'review_comment': reviewComment,
      if (requiredChanges != null) 'required_changes': requiredChanges,
    };
    if (clearReview) {
      map['reviewed_at'] = null;
      map['reviewed_by'] = null;
      map['review_comment'] = null;
      map['required_changes'] = [];
    }
    return map;
  }
}

const moduleCases = 'cases';
const moduleImages = 'images';
const moduleLearning = 'learning';
const moduleRecords = 'records';

const moduleTypes = [moduleCases, moduleImages, moduleLearning, moduleRecords];

const statusDraft = 'draft';
const statusSubmitted = 'submitted';
const statusNeedsRevision = 'needs_revision';
const statusApproved = 'approved';
const statusRejected = 'rejected';
