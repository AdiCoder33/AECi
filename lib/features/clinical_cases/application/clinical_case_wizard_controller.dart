import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/clinical_cases_repository.dart';
import '../data/clinical_case_constants.dart';
import '../domain/constants/anterior_segment_options.dart';
import '../domain/constants/fundus_options.dart';

class ClinicalCaseWizardState {
  const ClinicalCaseWizardState({
    required this.caseId,
    required this.isLoading,
    required this.errorMessage,
    required this.caseType,
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
    required this.systemicOther,
    required this.bcvaRe,
    required this.bcvaLe,
    required this.iopRe,
    required this.iopLe,
    required this.anteriorSegment,
    required this.fundus,
    required this.diagnosis,
    required this.keywords,
    required this.status,
  });

  final String? caseId;
  final bool isLoading;
  final String? errorMessage;
  final String? caseType;
  final DateTime dateOfExamination;
  final String patientName;
  final String uidNumber;
  final String mrNumber;
  final String patientGender;
  final int? patientAge;
  final String chiefComplaint;
  final int? complaintDurationValue;
  final String complaintDurationUnit;
  final List<String> systemicHistory;
  final String systemicOther;
  final String bcvaRe;
  final String bcvaLe;
  final String iopRe;
  final String iopLe;
  final Map<String, dynamic> anteriorSegment;
  final Map<String, dynamic> fundus;
  final String diagnosis;
  final List<String> keywords;
  final String status;

  factory ClinicalCaseWizardState.initial() => ClinicalCaseWizardState(
    caseId: null,
    isLoading: false,
    errorMessage: null,
    caseType: null,
    dateOfExamination: DateTime.now(),
    patientName: '',
    uidNumber: '',
    mrNumber: '',
    patientGender: 'male',
    patientAge: null,
    chiefComplaint: '',
    complaintDurationValue: null,
    complaintDurationUnit: complaintUnits.first,
    systemicHistory: const [],
    systemicOther: '',
    bcvaRe: '',
    bcvaLe: '',
    iopRe: '',
    iopLe: '',
    anteriorSegment: _initialAnterior(),
    fundus: _initialFundus(),
    diagnosis: '',
    keywords: const [],
    status: 'draft',
  );

  ClinicalCaseWizardState copyWith({
    String? caseId,
    bool? isLoading,
    String? errorMessage,
    String? caseType,
    DateTime? dateOfExamination,
    String? patientName,
    String? uidNumber,
    String? mrNumber,
    String? patientGender,
    int? patientAge,
    String? chiefComplaint,
    int? complaintDurationValue,
    String? complaintDurationUnit,
    List<String>? systemicHistory,
    String? systemicOther,
    String? bcvaRe,
    String? bcvaLe,
    String? iopRe,
    String? iopLe,
    Map<String, dynamic>? anteriorSegment,
    Map<String, dynamic>? fundus,
    String? diagnosis,
    List<String>? keywords,
    String? status,
  }) {
    return ClinicalCaseWizardState(
      caseId: caseId ?? this.caseId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      caseType: caseType ?? this.caseType,
      dateOfExamination: dateOfExamination ?? this.dateOfExamination,
      patientName: patientName ?? this.patientName,
      uidNumber: uidNumber ?? this.uidNumber,
      mrNumber: mrNumber ?? this.mrNumber,
      patientGender: patientGender ?? this.patientGender,
      patientAge: patientAge ?? this.patientAge,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      complaintDurationValue:
          complaintDurationValue ?? this.complaintDurationValue,
      complaintDurationUnit:
          complaintDurationUnit ?? this.complaintDurationUnit,
      systemicHistory: systemicHistory ?? this.systemicHistory,
      systemicOther: systemicOther ?? this.systemicOther,
      bcvaRe: bcvaRe ?? this.bcvaRe,
      bcvaLe: bcvaLe ?? this.bcvaLe,
      iopRe: iopRe ?? this.iopRe,
      iopLe: iopLe ?? this.iopLe,
      anteriorSegment: anteriorSegment ?? this.anteriorSegment,
      fundus: fundus ?? this.fundus,
      diagnosis: diagnosis ?? this.diagnosis,
      keywords: keywords ?? this.keywords,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap(String statusValue) {
    final date = dateOfExamination.toIso8601String().split('T').first;
    final cleanedKeywords = _applyCaseTypeKeywords(keywords, caseType);
    final systemic = [
      ...systemicHistory,
      if (systemicOther.trim().isNotEmpty) 'Others: ${systemicOther.trim()}',
    ];
    return {
      'date_of_examination': date,
      'patient_name': patientName.trim(),
      'uid_number': uidNumber.trim(),
      'mr_number': mrNumber.trim(),
      'patient_gender': patientGender,
      'patient_age': patientAge ?? 0,
      'chief_complaint': chiefComplaint.trim(),
      'complaint_duration_value': complaintDurationValue ?? 0,
      'complaint_duration_unit': complaintDurationUnit,
      'systemic_history': systemic,
      'bcva_re': bcvaRe.isEmpty ? null : bcvaRe,
      'bcva_le': bcvaLe.isEmpty ? null : bcvaLe,
      'iop_re': iopRe.isEmpty ? null : num.tryParse(iopRe),
      'iop_le': iopLe.isEmpty ? null : num.tryParse(iopLe),
      'anterior_segment': anteriorSegment,
      'fundus': fundus,
      'diagnosis': diagnosis.trim(),
      'keywords': cleanedKeywords,
      'status': statusValue,
    };
  }
}

class ClinicalCaseWizardController
    extends StateNotifier<ClinicalCaseWizardState> {
  ClinicalCaseWizardController(this._repo)
    : super(ClinicalCaseWizardState.initial());

  final ClinicalCasesRepository _repo;

  Future<void> loadCase(String caseId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await _repo.getCase(caseId);
      final systemic = data.systemicHistory
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
      var other = '';
      final filtered = <String>[];
      for (final item in systemic) {
        if (item.toLowerCase().startsWith('others:')) {
          other = item.substring(7).trim();
        } else {
          filtered.add(item);
        }
      }
      state = state.copyWith(
        caseId: data.id,
        dateOfExamination: data.dateOfExamination,
        patientName: data.patientName,
        uidNumber: data.uidNumber,
        mrNumber: data.mrNumber,
        patientGender: data.patientGender,
        patientAge: data.patientAge,
        chiefComplaint: data.chiefComplaint,
        complaintDurationValue: data.complaintDurationValue,
        complaintDurationUnit: data.complaintDurationUnit,
        systemicHistory: filtered,
        systemicOther: other,
        bcvaRe: data.bcvaRe ?? '',
        bcvaLe: data.bcvaLe ?? '',
        iopRe: data.iopRe?.toString() ?? '',
        iopLe: data.iopLe?.toString() ?? '',
        anteriorSegment: _normalizeAnterior(
          data.anteriorSegment ?? _initialAnterior(),
        ),
        fundus: _normalizeFundus(data.fundus ?? _initialFundus()),
        diagnosis: data.diagnosis,
        keywords: _applyCaseTypeKeywords(
          data.keywords,
          state.caseType ?? _detectCaseType(data.keywords),
        ),
        status: data.status,
        caseType: state.caseType ?? _detectCaseType(data.keywords),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void update({
    DateTime? dateOfExamination,
    String? patientName,
    String? uidNumber,
    String? mrNumber,
    String? patientGender,
    int? patientAge,
    String? chiefComplaint,
    int? complaintDurationValue,
    String? complaintDurationUnit,
    List<String>? systemicHistory,
    String? systemicOther,
    String? bcvaRe,
    String? bcvaLe,
    String? iopRe,
    String? iopLe,
    Map<String, dynamic>? anteriorSegment,
    Map<String, dynamic>? fundus,
    String? diagnosis,
    List<String>? keywords,
    String? status,
    String? caseType,
  }) {
    final nextCaseType = caseType ?? state.caseType;
    final nextKeywords = keywords == null
        ? null
        : _applyCaseTypeKeywords(keywords, nextCaseType);
    state = state.copyWith(
      dateOfExamination: dateOfExamination,
      patientName: patientName,
      uidNumber: uidNumber,
      mrNumber: mrNumber,
      patientGender: patientGender,
      patientAge: patientAge,
      chiefComplaint: chiefComplaint,
      complaintDurationValue: complaintDurationValue,
      complaintDurationUnit: complaintDurationUnit,
      systemicHistory: systemicHistory,
      systemicOther: systemicOther,
      bcvaRe: bcvaRe,
      bcvaLe: bcvaLe,
      iopRe: iopRe,
      iopLe: iopLe,
      anteriorSegment: anteriorSegment,
      fundus: fundus,
      diagnosis: diagnosis,
      keywords: nextKeywords,
      status: status,
      caseType: nextCaseType,
    );
  }

  void setCaseType(String? caseType) {
    final normalized = caseType?.toLowerCase();
    final nextKeywords = _applyCaseTypeKeywords(state.keywords, normalized);
    state = state.copyWith(caseType: normalized, keywords: nextKeywords);
  }

  Future<String> save({required String status}) async {
    final effectiveKeywords = _applyCaseTypeKeywords(
      state.keywords,
      state.caseType,
    );
    state = state.copyWith(keywords: effectiveKeywords);
    final data = state.toMap(status);
    if (state.caseId == null) {
      final id = await _repo.createCaseDraft(data);
      state = state.copyWith(caseId: id, status: status);
      return id;
    }
    await _repo.updateCaseDraft(state.caseId!, data);
    state = state.copyWith(status: status);
    return state.caseId!;
  }

  void setLidsFindings({required String eye, required List<String> findings}) {
    setAnteriorSegmentSelection(
      eye: eye,
      sectionKey: 'lids',
      selectedList: findings,
    );
  }

  void setLidsOtherNotes({required String eye, required String notes}) {
    setAnteriorSegmentOther(eye: eye, sectionKey: 'lids', otherText: notes);
  }

  void setAnteriorSegmentSelection({
    required String eye,
    required String sectionKey,
    required List<String> selectedList,
  }) {
    final next = _copyAnterior(state.anteriorSegment);
    final eyeMap = Map<String, dynamic>.from(next[eye] as Map? ?? {});
    final section = Map<String, dynamic>.from(eyeMap[sectionKey] as Map? ?? {});
    final normalOption = _normalOptionForAnteriorSection(sectionKey);
    var normalized = _normalizeSelection(selectedList);
    if (normalized.contains(normalOption) && normalized.length > 1) {
      normalized = [normalOption];
    }
    section['selected'] = normalized;
    final descriptions = Map<String, dynamic>.from(
      section['descriptions'] as Map? ?? {},
    );
    descriptions.removeWhere((key, _) => !normalized.contains(key));
    section['descriptions'] = descriptions;
    if (!normalized.contains('Other')) {
      section['other'] = '';
    }
    eyeMap[sectionKey] = section;
    next[eye] = eyeMap;
    state = state.copyWith(anteriorSegment: next);
  }

  void setAnteriorSegmentDescription({
    required String eye,
    required String sectionKey,
    required String option,
    required String description,
  }) {
    final next = _copyAnterior(state.anteriorSegment);
    final eyeMap = Map<String, dynamic>.from(next[eye] as Map? ?? {});
    final section = Map<String, dynamic>.from(eyeMap[sectionKey] as Map? ?? {});
    final descriptions = Map<String, dynamic>.from(
      section['descriptions'] as Map? ?? {},
    );
    descriptions[option] = description;
    section['descriptions'] = descriptions;
    eyeMap[sectionKey] = section;
    next[eye] = eyeMap;
    state = state.copyWith(anteriorSegment: next);
  }

  void setAnteriorSegmentOther({
    required String eye,
    required String sectionKey,
    required String otherText,
  }) {
    final next = _copyAnterior(state.anteriorSegment);
    final eyeMap = Map<String, dynamic>.from(next[eye] as Map? ?? {});
    final section = Map<String, dynamic>.from(eyeMap[sectionKey] as Map? ?? {});
    section['other'] = otherText;
    eyeMap[sectionKey] = section;
    next[eye] = eyeMap;
    state = state.copyWith(anteriorSegment: next);
  }

  void setAnteriorSegmentRemarks({
    required String eye,
    required String remarks,
  }) {
    final next = _copyAnterior(state.anteriorSegment);
    final eyeMap = Map<String, dynamic>.from(next[eye] as Map? ?? {});
    eyeMap['remarks'] = remarks;
    next[eye] = eyeMap;
    state = state.copyWith(anteriorSegment: next);
  }

  void setFundusSelection({
    required String sectionKey,
    required List<String> selectedList,
    String? eye,
  }) {
    final targetEye = eye ?? 'RE';
    final next = _copyFundus(state.fundus);
    final eyeMap = Map<String, dynamic>.from(next[targetEye] as Map? ?? {});
    final section = Map<String, dynamic>.from(eyeMap[sectionKey] as Map? ?? {});
    final normalOption = _normalOptionForFundusSection(sectionKey);
    var normalized = _normalizeSelection(selectedList);
    if (normalized.contains(normalOption) && normalized.length > 1) {
      normalized = [normalOption];
    }
    section['selected'] = normalized;
    final descriptions = Map<String, dynamic>.from(
      section['descriptions'] as Map? ?? {},
    );
    descriptions.removeWhere((key, _) => !normalized.contains(key));
    section['descriptions'] = descriptions;
    if (!normalized.contains('Other')) {
      section['other'] = '';
    }
    eyeMap[sectionKey] = section;
    next[targetEye] = eyeMap;
    state = state.copyWith(fundus: next);
  }

  void setFundusDescription({
    required String sectionKey,
    required String option,
    required String description,
    String? eye,
  }) {
    final targetEye = eye ?? 'RE';
    final next = _copyFundus(state.fundus);
    final eyeMap = Map<String, dynamic>.from(next[targetEye] as Map? ?? {});
    final section = Map<String, dynamic>.from(eyeMap[sectionKey] as Map? ?? {});
    final descriptions = Map<String, dynamic>.from(
      section['descriptions'] as Map? ?? {},
    );
    descriptions[option] = description;
    section['descriptions'] = descriptions;
    eyeMap[sectionKey] = section;
    next[targetEye] = eyeMap;
    state = state.copyWith(fundus: next);
  }

  void setFundusOther({
    required String sectionKey,
    required String otherText,
    String? eye,
  }) {
    final targetEye = eye ?? 'RE';
    final next = _copyFundus(state.fundus);
    final eyeMap = Map<String, dynamic>.from(next[targetEye] as Map? ?? {});
    final section = Map<String, dynamic>.from(eyeMap[sectionKey] as Map? ?? {});
    section['other'] = otherText;
    eyeMap[sectionKey] = section;
    next[targetEye] = eyeMap;
    state = state.copyWith(fundus: next);
  }

  void setFundusRemarks({required String remarks, String? eye}) {
    final targetEye = eye ?? 'RE';
    final next = _copyFundus(state.fundus);
    final eyeMap = Map<String, dynamic>.from(next[targetEye] as Map? ?? {});
    eyeMap['remarks'] = remarks;
    next[targetEye] = eyeMap;
    state = state.copyWith(fundus: next);
  }
}

final clinicalCaseWizardProvider =
    StateNotifierProvider.autoDispose<
      ClinicalCaseWizardController,
      ClinicalCaseWizardState
    >((ref) {
      return ClinicalCaseWizardController(
        ref.watch(clinicalCasesRepositoryProvider),
      );
    });

Map<String, dynamic> _initialAnterior() {
  final re = <String, dynamic>{};
  final le = <String, dynamic>{};
  for (final section in anteriorSegmentSections) {
    re[section.key] = _emptyAnteriorSection();
    le[section.key] = _emptyAnteriorSection();
  }
  re['remarks'] = '';
  le['remarks'] = '';
  return {'RE': re, 'LE': le};
}

Map<String, dynamic> _normalizeAnterior(Map<String, dynamic> anterior) {
  final hasEyes = anterior.containsKey('RE') || anterior.containsKey('LE');
  final source = hasEyes ? anterior : {'RE': anterior, 'LE': {}};
  final next = _copyAnterior(source);
  for (final eyeKey in ['RE', 'LE']) {
    final rawEye = Map<String, dynamic>.from(next[eyeKey] as Map? ?? {});
    final eye = <String, dynamic>{};
    for (final section in anteriorSegmentSections) {
      final key = section.key;
      if (rawEye[key] is Map) {
        eye[key] = _normalizeSection(rawEye[key] as Map);
        continue;
      }
      if (key == 'lids' && rawEye['lids_findings'] is List) {
        final list = (rawEye['lids_findings'] as List?)?.cast<String>() ?? [];
        final otherNotes = (rawEye['lids_other_notes'] as String?) ?? '';
        eye[key] = {
          'selected': _normalizeSelection(list),
          'descriptions': <String, String>{},
          'other': otherNotes,
        };
        continue;
      }
      final legacyLabel = _legacyAnteriorLabel(key);
      if (legacyLabel != null && rawEye[legacyLabel] is Map) {
        final legacy = rawEye[legacyLabel] as Map;
        final status = (legacy['status'] as String?) ?? 'normal';
        final notes = (legacy['notes'] as String?) ?? '';
        if (status == 'abnormal' && notes.trim().isNotEmpty) {
          eye[key] = {
            'selected': <String>['Other'],
            'descriptions': <String, String>{},
            'other': notes,
          };
        } else {
          eye[key] = _emptyAnteriorSection();
        }
        continue;
      }
      eye[key] = _emptyAnteriorSection();
    }
    eye['remarks'] = (rawEye['remarks'] as String?) ?? '';
    next[eyeKey] = eye;
  }
  return next;
}

Map<String, dynamic> _copyAnterior(Map<String, dynamic> source) {
  final copy = <String, dynamic>{};
  for (final entry in source.entries) {
    if (entry.value is Map) {
      copy[entry.key] = Map<String, dynamic>.from(entry.value as Map);
    } else {
      copy[entry.key] = entry.value;
    }
  }
  return copy;
}

Map<String, dynamic> _initialFundus() {
  return {'RE': _emptyFundusEye(), 'LE': _emptyFundusEye()};
}

Map<String, dynamic> _emptyFundusEye() {
  final eye = <String, dynamic>{};
  for (final section in fundusSections) {
    eye[section.key] = _emptyFundusSection();
  }
  eye['remarks'] = '';
  return eye;
}

Map<String, dynamic> _normalizeFundus(Map<String, dynamic> fundus) {
  final hasEyes = fundus.containsKey('RE') || fundus.containsKey('LE');
  final source = hasEyes ? fundus : {'RE': fundus, 'LE': {}};
  final next = _copyFundus(source);
  for (final eyeKey in ['RE', 'LE']) {
    final rawEye = Map<String, dynamic>.from(next[eyeKey] as Map? ?? {});
    final eye = <String, dynamic>{};
    for (final section in fundusSections) {
      if (rawEye[section.key] is Map) {
        eye[section.key] = _normalizeSection(rawEye[section.key] as Map);
      } else {
        final legacy = _legacyFundusValue(rawEye, section.key);
        if (legacy.isNotEmpty) {
          eye[section.key] = {
            'selected': <String>[legacy],
            'descriptions': <String, String>{},
            'other': '',
          };
        } else {
          eye[section.key] = _emptyFundusSection();
        }
      }
    }
    eye['remarks'] = (rawEye['remarks'] as String?) ?? '';
    next[eyeKey] = eye;
  }
  return next;
}

Map<String, dynamic> _copyFundus(Map<String, dynamic> source) {
  final copy = <String, dynamic>{};
  for (final entry in source.entries) {
    if (entry.value is Map) {
      copy[entry.key] = Map<String, dynamic>.from(entry.value as Map);
    } else {
      copy[entry.key] = entry.value;
    }
  }
  return copy;
}

Map<String, dynamic> _emptyAnteriorSection() {
  return {
    'selected': <String>[],
    'descriptions': <String, String>{},
    'other': '',
  };
}

Map<String, dynamic> _emptyFundusSection() {
  return {
    'selected': <String>[],
    'descriptions': <String, String>{},
    'other': '',
  };
}

Map<String, dynamic> _normalizeSection(Map raw) {
  final selected = (raw['selected'] as List?)?.cast<String>() ?? <String>[];
  final descriptions = Map<String, String>.from(
    raw['descriptions'] as Map? ?? {},
  );
  final other = (raw['other'] as String?) ?? '';

  return {
    'selected': _normalizeSelection(selected),
    'descriptions': descriptions,
    'other': other,
  };
}

List<String> _normalizeSelection(List<String> selected) {
  final deduped = <String>{};
  for (final item in selected) {
    if (item.trim().isEmpty) continue;
    deduped.add(item);
  }
  final list = deduped.toList();
  if (list.contains('Normal') && list.length > 1) {
    return ['Normal'];
  }
  return list;
}

String _normalOptionForAnteriorSection(String sectionKey) {
  const normalMap = {
    'lids': 'Normal',
    'conjunctiva': 'Normal',
    'cornea': 'Clear',
    'anterior_chamber': 'Normal Depth',
    'iris': 'Normal colour and pattern',
    'pupil': 'Normal size and reaction to light',
    'lens': 'Clear',
    'ocular_movements': 'Full and free',
    'corneal_reflex': 'Normal',
    'globe': 'Normal',
  };
  final mapped = normalMap[sectionKey];
  if (mapped != null) return mapped;
  return 'Normal';
}

String _normalOptionForFundusSection(String sectionKey) {
  const normalMap = {
    'media': 'Clear',
    'optic_disc': 'Normal',
    'vessels': 'Normal',
    'background_retina': 'Normal',
    'macula': 'Present',
  };
  final mapped = normalMap[sectionKey];
  if (mapped != null) return mapped;
  return 'Normal';
}

String? _detectCaseType(List<String> keywords) {
  for (final keyword in keywords) {
    final normalized = keyword.trim().toLowerCase();
    if (normalized == 'rop') return 'rop';
  }
  return null;
}

List<String> _applyCaseTypeKeywords(List<String> keywords, String? caseType) {
  final deduped = <String>[];
  for (final keyword in keywords) {
    final cleaned = keyword.trim();
    if (cleaned.isEmpty) continue;
    final exists = deduped.any((e) => e.toLowerCase() == cleaned.toLowerCase());
    if (!exists) deduped.add(cleaned);
  }
  if (caseType != null) {
    final forced = caseType.toLowerCase();
    final exists = deduped.any((e) => e.toLowerCase() == forced);
    if (!exists) deduped.add(forced);
  }
  return deduped;
}

String? _legacyAnteriorLabel(String sectionKey) {
  switch (sectionKey) {
    case 'conjunctiva':
      return 'Conjunctiva';
    case 'cornea':
      return 'Cornea';
    case 'anterior_chamber':
      return 'Anterior Chamber';
    case 'pupil':
      return 'Pupil';
    case 'lens':
      return 'Lens';
    case 'iris':
      return 'Iris';
  }
  return null;
}

String _legacyFundusValue(Map<String, dynamic> rawEye, String sectionKey) {
  switch (sectionKey) {
    case 'media':
      return (rawEye['media'] as String?) ?? (rawEye['Media'] as String?) ?? '';
    case 'optic_disc':
      return (rawEye['optic_disc'] as String?) ??
          (rawEye['disc'] as String?) ??
          '';
    case 'vessels':
      return (rawEye['vessels'] as String?) ?? '';
    case 'background_retina':
      return (rawEye['background_retina'] as String?) ??
          (rawEye['background'] as String?) ??
          '';
    case 'macula':
      return (rawEye['macula'] as String?) ?? '';
  }
  return '';
}
