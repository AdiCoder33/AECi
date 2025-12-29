import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/clinical_cases_repository.dart';
import '../data/clinical_case_constants.dart';

class ClinicalCaseWizardState {
  const ClinicalCaseWizardState({
    required this.caseId,
    required this.isLoading,
    required this.errorMessage,
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
    final cleanedKeywords = keywords.toList();
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
        keywords: data.keywords,
        status: data.status,
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
  }) {
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
      keywords: keywords,
      status: status,
    );
  }

  Future<String> save({required String status}) async {
    // Print the current user's UID for debugging RLS issues
    print(
      '[DEBUG] Current user UID: ${Supabase.instance.client.auth.currentUser?.id}',
    );
    final data = state.toMap(status);
    print('[DEBUG] save() called with data:');
    print(data);
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
    final next = _copyAnterior(state.anteriorSegment);
    final eyeMap = Map<String, dynamic>.from(next[eye] as Map? ?? {});
    eyeMap['lids_findings'] = findings;
    if (!findings.contains('Other')) {
      eyeMap['lids_other_notes'] = '';
    }
    next[eye] = eyeMap;
    state = state.copyWith(anteriorSegment: next);
  }

  void setLidsOtherNotes({required String eye, required String notes}) {
    final next = _copyAnterior(state.anteriorSegment);
    final eyeMap = Map<String, dynamic>.from(next[eye] as Map? ?? {});
    eyeMap['lids_other_notes'] = notes;
    next[eye] = eyeMap;
    state = state.copyWith(anteriorSegment: next);
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
  final re = <String, dynamic>{
    'lids_findings': <String>['Normal'],
    'lids_other_notes': '',
  };
  final le = <String, dynamic>{
    'lids_findings': <String>['Normal'],
    'lids_other_notes': '',
  };
  for (final field in anteriorSegments) {
    re[field] = {'status': 'normal', 'notes': ''};
    le[field] = {'status': 'normal', 'notes': ''};
  }
  return {'RE': re, 'LE': le};
}

Map<String, dynamic> _normalizeAnterior(Map<String, dynamic> anterior) {
  final next = _copyAnterior(anterior);
  for (final eyeKey in ['RE', 'LE']) {
    final eye = Map<String, dynamic>.from(next[eyeKey] as Map? ?? {});
    if (!eye.containsKey('lids_findings')) {
      final legacy = eye['Lids'] as Map?;
      if (legacy != null) {
        final status = legacy['status'] as String? ?? 'normal';
        final notes = (legacy['notes'] as String?) ?? '';
        if (status == 'normal') {
          eye['lids_findings'] = <String>['Normal'];
          eye['lids_other_notes'] = '';
        } else if (notes.trim().length >= 3) {
          eye['lids_findings'] = <String>['Other'];
          eye['lids_other_notes'] = notes;
        } else {
          eye['lids_findings'] = <String>['Normal'];
          eye['lids_other_notes'] = '';
        }
      } else {
        eye['lids_findings'] = <String>['Normal'];
        eye['lids_other_notes'] = '';
      }
    } else {
      final list = (eye['lids_findings'] as List?)?.cast<String>() ?? [];
      if (list.isEmpty) {
        eye['lids_findings'] = <String>['Normal'];
      }
    }
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
  return {'RE': _emptyFundus(), 'LE': _emptyFundus()};
}

Map<String, dynamic> _emptyFundus() {
  return {
    'media': '',
    'disc': '',
    'vessels': '',
    'background': '',
    'macula': '',
    'others': '',
  };
}

Map<String, dynamic> _normalizeFundus(Map<String, dynamic> fundus) {
  if (fundus.containsKey('RE') || fundus.containsKey('LE')) {
    final re = Map<String, dynamic>.from(fundus['RE'] as Map? ?? {});
    final le = Map<String, dynamic>.from(fundus['LE'] as Map? ?? {});
    return {'RE': _ensureFundus(re), 'LE': _ensureFundus(le)};
  }
  return {'RE': _ensureFundus(fundus), 'LE': _ensureFundus({})};
}

Map<String, dynamic> _ensureFundus(Map<String, dynamic> fundus) {
  final next = _emptyFundus();
  for (final entry in fundus.entries) {
    if (next.containsKey(entry.key)) {
      next[entry.key] = entry.value;
    }
  }
  return next;
}
