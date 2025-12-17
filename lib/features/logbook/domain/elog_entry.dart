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
      authorProfile: map['profiles'] == null
          ? null
          : Map<String, dynamic>.from(map['profiles'] as Map),
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
  });

  final String? patientUniqueId;
  final String? mrn;
  final List<String>? keywords;
  final Map<String, dynamic>? payload;
  final String? status;

  Map<String, dynamic> toUpdateMap() {
    return {
      if (patientUniqueId != null) 'patient_unique_id': patientUniqueId,
      if (mrn != null) 'mrn': mrn,
      if (keywords != null) 'keywords': keywords,
      if (payload != null) 'payload': jsonDecode(jsonEncode(payload)),
      if (status != null) 'status': status,
    };
  }
}

const moduleCases = 'cases';
const moduleImages = 'images';
const moduleLearning = 'learning';
const moduleRecords = 'records';

const moduleTypes = [moduleCases, moduleImages, moduleLearning, moduleRecords];
