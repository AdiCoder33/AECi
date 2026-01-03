import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/clinical_case_wizard_controller.dart';
import '../../application/clinical_cases_controller.dart';
import '../../data/clinical_case_constants.dart';
import '../../domain/constants/anterior_segment_options.dart';
import '../../domain/constants/fundus_options.dart';
import 'steps/step1_patient.dart';
import 'steps/step2_complaints.dart';
import 'steps/step3_systemic.dart';
import 'steps/step4_bcva.dart';
import 'steps/step5_iop.dart';
import 'steps/step6_anterior.dart';
import 'steps/step6_uvea_anterior.dart';
import 'steps/step7_fundus.dart';
import 'steps/step7_uvea_fundus.dart';
import 'steps/step8_uvea_location.dart';
import 'steps/step8_diagnosis_keywords.dart';
import 'widgets/wizard_footer.dart';
import 'widgets/wizard_header.dart';

class ClinicalCaseWizardScreen extends ConsumerStatefulWidget {
  const ClinicalCaseWizardScreen({super.key, this.caseId, this.caseType});

  final String? caseId;
  final String? caseType;

  @override
  ConsumerState<ClinicalCaseWizardScreen> createState() =>
      _ClinicalCaseWizardScreenState();
}

class _ClinicalCaseWizardScreenState
    extends ConsumerState<ClinicalCaseWizardScreen> {
  final _formKeys = List.generate(9, (_) => GlobalKey<FormState>());
  final _patientNameController = TextEditingController();
  final _uidController = TextEditingController();
  final _mrController = TextEditingController();
  final _ageController = TextEditingController();
  final _chiefController = TextEditingController();
  final _durationController = TextEditingController();
  final _systemicOtherController = TextEditingController();
  final _iopReController = TextEditingController();
  final _iopLeController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _diagnosisReController = TextEditingController();
  final _diagnosisLeController = TextEditingController();
  final _keywordsController = TextEditingController();
  int _stepIndex = 0;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    _bindControllers();
    if (widget.caseType != null) {
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted) return;
  ref
      .read(clinicalCaseWizardProvider.notifier)
      .setCaseType(widget.caseType);
});

      if (widget.caseId == null) {
        _keywordsController.text = widget.caseType!;
      }
    }
    if (widget.caseId != null) {
      Future.microtask(() {
        ref.read(clinicalCaseWizardProvider.notifier).loadCase(widget.caseId!);
      });
    }
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _uidController.dispose();
    _mrController.dispose();
    _ageController.dispose();
    _chiefController.dispose();
    _durationController.dispose();
    _systemicOtherController.dispose();
    _iopReController.dispose();
    _iopLeController.dispose();
    _diagnosisController.dispose();
    _diagnosisReController.dispose();
    _diagnosisLeController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  void _bindControllers() {
    final notifier = ref.read(clinicalCaseWizardProvider.notifier);
    _patientNameController.addListener(() {
      notifier.update(patientName: _patientNameController.text);
    });
    _uidController.addListener(() {
      notifier.update(uidNumber: _uidController.text);
    });
    _mrController.addListener(() {
      notifier.update(mrNumber: _mrController.text);
    });
    _ageController.addListener(() {
      notifier.update(patientAge: int.tryParse(_ageController.text));
    });
    _chiefController.addListener(() {
      notifier.update(chiefComplaint: _chiefController.text);
    });
    _durationController.addListener(() {
      notifier.update(
        complaintDurationValue: int.tryParse(_durationController.text),
      );
    });
    _systemicOtherController.addListener(() {
      notifier.update(systemicOther: _systemicOtherController.text);
    });
    _iopReController.addListener(() {
      notifier.update(iopRe: _iopReController.text);
    });
    _iopLeController.addListener(() {
      notifier.update(iopLe: _iopLeController.text);
    });
    _diagnosisController.addListener(() {
      notifier.update(diagnosis: _diagnosisController.text);
    });
  }

  void _prefillFromState(ClinicalCaseWizardState state) {
    _prefilled = true;
    _patientNameController.text = state.patientName;
    _uidController.text = state.uidNumber;
    _mrController.text = state.mrNumber;
    _ageController.text = state.patientAge?.toString() ?? '';
    _chiefController.text = state.chiefComplaint;
    _durationController.text = state.complaintDurationValue?.toString() ?? '';
    _systemicOtherController.text = state.systemicOther;
    _iopReController.text = state.iopRe;
    _iopLeController.text = state.iopLe;
    _diagnosisController.text = state.diagnosis;
    _keywordsController.text = state.keywords.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(clinicalCaseWizardProvider);
    final notifier = ref.read(clinicalCaseWizardProvider.notifier);
    ref.listen<ClinicalCaseWizardState>(clinicalCaseWizardProvider, (
      previous,
      next,
    ) {
      if (next.caseId != null && !_prefilled && !next.isLoading) {
        _prefillFromState(next);
      }
    });

    if (wizard.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isUvea =
        (wizard.caseType ?? widget.caseType ?? '').toLowerCase() == 'uvea';
    final titles = isUvea
        ? [
            'Patient Details',
            'Chief Complaints',
            'Systemic History',
            'BCVA',
            'IOP',
            'Uvea Anterior Segment',
            'Uvea Fundus Examination',
            'Uveitis Location',
            'Diagnosis & Keywords',
          ]
        : [
            'Patient Details',
            'Chief Complaints',
            'Systemic History',
            'BCVA',
            'IOP',
            'Anterior Segment',
            'Fundus Examination',
            'Diagnosis & Keywords',
          ];

    final steps = <Widget>[
      Step1Patient(
        formKey: _formKeys[0],
        examDate: wizard.dateOfExamination,
        onPickDate: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: wizard.dateOfExamination,
            firstDate: DateTime(now.year - 10),
            lastDate: now,
          );
          if (picked != null) {
            notifier.update(dateOfExamination: picked);
          }
        },
        patientNameController: _patientNameController,
        uidController: _uidController,
        mrController: _mrController,
        ageController: _ageController,
        gender: wizard.patientGender,
        onGenderChanged: (value) => notifier.update(patientGender: value),
      ),
      Step2Complaints(
        formKey: _formKeys[1],
        chiefController: _chiefController,
        durationController: _durationController,
        durationUnit: wizard.complaintDurationUnit,
        onDurationUnitChanged: (value) =>
            notifier.update(complaintDurationUnit: value),
      ),
      Form(
        key: _formKeys[2],
        child: Step3Systemic(
          selected: wizard.systemicHistory,
          otherController: _systemicOtherController,
          onSelectionChanged: (next) => notifier.update(systemicHistory: next),
        ),
      ),
      Step4Bcva(
        formKey: _formKeys[3],
        bcvaRe: wizard.bcvaRe,
        bcvaLe: wizard.bcvaLe,
        onBcvaReChanged: (value) => notifier.update(bcvaRe: value),
        onBcvaLeChanged: (value) => notifier.update(bcvaLe: value),
      ),
      Step5Iop(
        formKey: _formKeys[4],
        iopReController: _iopReController,
        iopLeController: _iopLeController,
      ),
// ---------------- Step 6 ----------------
if (isUvea)
  Step6UveaAnterior(
    formKey: _formKeys[5],
    uveaAnterior: _uveaMap(wizard.anteriorSegment),
    onChanged: (eye, field, value) =>
        notifier.setUveaAnteriorField(
          eye: eye,
          field: field,
          value: value,
        ),
  )
else
  Step6Anterior(
    formKey: _formKeys[5],
    anterior: wizard.anteriorSegment,
    onSelectionChanged: (eye, sectionKey, selected) =>
        notifier.setAnteriorSegmentSelection(
          eye: eye,
          sectionKey: sectionKey,
          selectedList: selected,
        ),
    onDescriptionChanged: (eye, sectionKey, option, description) =>
        notifier.setAnteriorSegmentDescription(
          eye: eye,
          sectionKey: sectionKey,
          option: option,
          description: description,
        ),
    onOtherChanged: (eye, sectionKey, other) =>
        notifier.setAnteriorSegmentOther(
          eye: eye,
          sectionKey: sectionKey,
          otherText: other,
        ),
    onRemarksChanged: (eye, remarks) =>
        notifier.setAnteriorSegmentRemarks(
          eye: eye,
          remarks: remarks,
        ),
  ),

// ---------------- Step 7 ----------------
if (isUvea)
  Step7UveaFundus(
    formKey: _formKeys[6],
    uveaFundus: _uveaMap(wizard.fundus),
    onChanged: (eye, field, value) =>
        notifier.setUveaFundusField(
          eye: eye,
          field: field,
          value: value,
        ),
  )
else
  Step7Fundus(
    formKey: _formKeys[6],
    fundus: wizard.fundus,
    onSelectionChanged: (eye, sectionKey, selected) =>
        notifier.setFundusSelection(
          eye: eye,
          sectionKey: sectionKey,
          selectedList: selected,
        ),
    onDescriptionChanged: (eye, sectionKey, option, description) =>
        notifier.setFundusDescription(
          eye: eye,
          sectionKey: sectionKey,
          option: option,
          description: description,
        ),
    onOtherChanged: (eye, sectionKey, other) =>
        notifier.setFundusOther(
          eye: eye,
          sectionKey: sectionKey,
          otherText: other,
        ),
    onRemarksChanged: (eye, remarks) =>
        notifier.setFundusRemarks(
          eye: eye,
          remarks: remarks,
        ),
  ),

// ---------------- Step 8 (Uvea only) ----------------
if (isUvea)
  Step8UveaLocation(
    formKey: _formKeys[7],
    locations: _uveaLocationMap(wizard.fundus),
    onChanged: (eye, value) =>
        notifier.setUveaLocation(
          eye: eye,
          location: value,
        ),
  ),

      Step8DiagnosisKeywords(
        formKey: _formKeys[isUvea ? 8 : 7],
        diagnosisController: _diagnosisController,
        diagnosisReController: _diagnosisReController,
        diagnosisLeController: _diagnosisLeController,
        keywordsController: _keywordsController,
        diagnoses: _parseDiagnoses(wizard.diagnosis),
        diagnosesRe: _parseDiagnoses(wizard.diagnosisRe),
        diagnosesLe: _parseDiagnoses(wizard.diagnosisLe),
        onDiagnosesChanged: (value) =>
            notifier.update(diagnosis: value.join(', ')),
        onDiagnosesReChanged: (value) =>
            notifier.update(diagnosisRe: value.join(', ')),
        onDiagnosesLeChanged: (value) =>
            notifier.update(diagnosisLe: value.join(', ')),
        keywords: wizard.keywords,
        onKeywordsChanged: (value) => notifier.update(keywords: value),
      ),
    ];

    final isLast = _stepIndex == steps.length - 1;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF34D399)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.medical_information_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'New Clinical Case',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          WizardHeader(
            step: _stepIndex + 1,
            total: steps.length,
            title: titles[_stepIndex],
            patientInfo: _stepIndex > 0 && wizard.patientName.isNotEmpty
                ? PatientInfoSummary(
                    patientName: wizard.patientName,
                    uidNumber: wizard.uidNumber,
                    mrNumber: wizard.mrNumber,
                    age: wizard.patientAge?.toString() ?? '',
                    gender: wizard.patientGender,
                    examDate:
                        '${wizard.dateOfExamination.day.toString().padLeft(2, '0')}-${wizard.dateOfExamination.month.toString().padLeft(2, '0')}-${wizard.dateOfExamination.year}',
                  )
                : null,
          ),
          Expanded(
            child: IndexedStack(index: _stepIndex, children: steps),
          ),
          WizardFooter(
            isFirst: _stepIndex == 0,
            isLast: isLast,
            isNextEnabled: _canProceed(wizard),
            onBack: _stepIndex == 0 ? null : _goBack,
            onNext: _goNext,
            onSaveDraft: () => _saveCase(wizard, 'draft'),
            onSubmit: () => _saveCase(wizard, 'submitted'),
          ),
        ],
      ),
    );
  }

  void _goBack() {
    setState(() {
      _stepIndex = (_stepIndex - 1).clamp(0, _maxStepIndex());
    });
  }

  void _goNext() {
    if (!_validateStep(showErrors: true)) return;
    setState(() {
      _stepIndex = (_stepIndex + 1).clamp(0, _maxStepIndex());
    });
  }

  int _maxStepIndex() {
    final wizard = ref.read(clinicalCaseWizardProvider);
    final isUvea =
        (wizard.caseType ?? widget.caseType ?? '').toLowerCase() == 'uvea';
    return isUvea ? 8 : 7;
  }

  bool _canProceed(ClinicalCaseWizardState wizard) {
    return _isStepComplete(wizard);
  }

  bool _validateStep({
    ClinicalCaseWizardState? wizard,
    bool showErrors = false,
  }) {
    final ClinicalCaseWizardState state =
        wizard ?? ref.read(clinicalCaseWizardProvider);
    final isUvea =
        (state.caseType ?? widget.caseType ?? '').toLowerCase() == 'uvea';
    if (showErrors) {
      final formKey = _formKeys[_stepIndex];
      if (formKey.currentState != null) {
        final valid = formKey.currentState!.validate();
        if (!valid) return false;
      }
    }

    if (_stepIndex == 2) {
      if (state.systemicHistory.isEmpty) {
        if (showErrors) {
          _showError('Please select systemic history');
        }
        return false;
      }
      if (state.systemicHistory.contains('Others') &&
          state.systemicOther.trim().isEmpty) {
        if (showErrors) {
          _showError('Please specify other systemic history');
        }
        return false;
      }
    }

    if (isUvea) {
      if (_stepIndex == 5) {
        final issues = _uveaAnteriorIssues(state.anteriorSegment);
        if (issues.isNotEmpty) {
          if (showErrors) {
            _showError('Complete uvea anterior segment selections.');
          }
          return false;
        }
      }
      if (_stepIndex == 6) {
        final issues = _uveaFundusIssues(state.fundus);
        if (issues.isNotEmpty) {
          if (showErrors) {
            _showError('Complete uvea fundus selections for both eyes.');
          }
          return false;
        }
      }
      if (_stepIndex == 7) {
        if (!_uveaLocationComplete(state.fundus)) {
          if (showErrors) {
            _showError('Select uveitis location for both eyes.');
          }
          return false;
        }
      }
      if (_stepIndex == 8) {
        if (state.keywords.isEmpty || state.keywords.length > 5) {
          if (showErrors) {
            _showError('Enter 1-5 keywords.');
          }
          return false;
        }
      }
    } else {
      if (_stepIndex == 5) {
        final issues = _anteriorIssues(state.anteriorSegment);
        if (issues.isNotEmpty) {
          if (showErrors) {
            _showError('Complete anterior segment selections.');
          }
          return false;
        }
      }
      if (_stepIndex == 6) {
        final issues = _fundusIssues(state.fundus);
        if (issues.isNotEmpty) {
          if (showErrors) {
            _showError('Complete fundus selections for both eyes.');
          }
          return false;
        }
      }
      if (_stepIndex == 7) {
        if (state.keywords.isEmpty || state.keywords.length > 5) {
          if (showErrors) {
            _showError('Enter 1-5 keywords.');
          }
          return false;
        }
      }
    }

    return true;
  }

  bool _isStepComplete(ClinicalCaseWizardState state) {
    final isUvea =
        (state.caseType ?? widget.caseType ?? '').toLowerCase() == 'uvea';
    switch (_stepIndex) {
      case 0:
        return _patientNameController.text.trim().isNotEmpty &&
            _uidController.text.trim().isNotEmpty &&
            _mrController.text.trim().isNotEmpty &&
            int.tryParse(_ageController.text) != null;
      case 1:
        return _chiefController.text.trim().isNotEmpty &&
            int.tryParse(_durationController.text) != null &&
            (int.tryParse(_durationController.text) ?? 0) > 0;
      case 2:
        if (state.systemicHistory.isEmpty) return false;
        if (state.systemicHistory.contains('Others') &&
            state.systemicOther.trim().isEmpty) {
          return false;
        }
        return true;
      case 3:
        return state.bcvaRe.isNotEmpty && state.bcvaLe.isNotEmpty;
      case 4:
        return num.tryParse(_iopReController.text) != null &&
            num.tryParse(_iopLeController.text) != null;
      case 5:
        return isUvea
            ? _uveaAnteriorIssues(state.anteriorSegment).isEmpty
            : _anteriorIssues(state.anteriorSegment).isEmpty;
      case 6:
        return isUvea
            ? _uveaFundusIssues(state.fundus).isEmpty
            : _fundusIssues(state.fundus).isEmpty;
      case 7:
        if (isUvea) {
          return _uveaLocationComplete(state.fundus);
        }
        return _parseDiagnoses(state.diagnosis).isNotEmpty &&
            state.keywords.isNotEmpty &&
            state.keywords.length <= 5;
      case 8:
        if (isUvea) {
          return _parseDiagnoses(state.diagnosis).isNotEmpty &&
              state.keywords.isNotEmpty &&
              state.keywords.length <= 5;
        }
        return true;
      default:
        return true;
    }
  }

  List<String> _anteriorIssues(Map<String, dynamic> anterior) {
    final issues = <String>[];
    for (final eyeKey in ['RE', 'LE']) {
      final eye = Map<String, dynamic>.from(anterior[eyeKey] as Map? ?? {});
      for (final section in anteriorSegmentSections) {
        final sectionData = Map<String, dynamic>.from(
          eye[section.key] as Map? ?? {},
        );
        final selected =
            (sectionData['selected'] as List?)?.cast<String>() ?? <String>[];
        final descriptions = Map<String, dynamic>.from(
          sectionData['descriptions'] as Map? ?? {},
        );
        final other = (sectionData['other'] as String?) ?? '';
        final normalOption = _normalOptionForAnterior(section);
        if (selected.isEmpty) {
          issues.add('$eyeKey ${section.label}');
          continue;
        }
        if (selected.contains(normalOption) && selected.length > 1) {
          issues.add('$eyeKey ${section.label} normal exclusive');
        }
        if (selected.contains('Other') && other.trim().length < 3) {
          issues.add('$eyeKey ${section.label} other');
        }
        for (final option in selected) {
          if (_isDescriptiveOption(option)) {
            final desc = (descriptions[option] ?? '').toString();
            if (desc.trim().length < 3) {
              issues.add('$eyeKey ${section.label} $option');
            }
          }
        }
      }
    }
    return issues;
  }

  String _normalOptionForAnterior(AnteriorSection section) {
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
    final mapped = normalMap[section.key];
    if (mapped != null && section.options.contains(mapped)) {
      return mapped;
    }
    if (section.options.contains('Normal')) return 'Normal';
    return section.options.isNotEmpty ? section.options.first : 'Normal';
  }

  List<String> _fundusIssues(Map<String, dynamic> fundus) {
    final issues = <String>[];
    for (final eyeKey in ['RE', 'LE']) {
      final eye = Map<String, dynamic>.from(fundus[eyeKey] as Map? ?? {});
      for (final section in fundusSections) {
        final sectionData = Map<String, dynamic>.from(
          eye[section.key] as Map? ?? {},
        );
        final selected =
            (sectionData['selected'] as List?)?.cast<String>() ?? <String>[];
        final descriptions = Map<String, dynamic>.from(
          sectionData['descriptions'] as Map? ?? {},
        );
        final other = (sectionData['other'] as String?) ?? '';
        final normalOption = _normalOptionForFundus(section);
        if (selected.isEmpty) {
          issues.add('$eyeKey ${section.label}');
          continue;
        }
        if (selected.contains(normalOption) && selected.length > 1) {
          issues.add('$eyeKey ${section.label} normal exclusive');
        }
        if (selected.contains('Other') && other.trim().length < 3) {
          issues.add('$eyeKey ${section.label} other');
        }
        for (final option in selected) {
          if (_isDescriptiveOption(option)) {
            final desc = (descriptions[option] ?? '').toString();
            if (desc.trim().length < 3) {
              issues.add('$eyeKey ${section.label} $option');
            }
          }
        }
      }
    }
    return issues;
  }

  Map<String, dynamic> _uveaMap(Map<String, dynamic> source) {
    return Map<String, dynamic>.from(source['uvea'] as Map? ?? {});
  }

  Map<String, dynamic> _uveaLocationMap(Map<String, dynamic> fundus) {
    return Map<String, dynamic>.from(
      fundus['uvea_location'] as Map? ?? {},
    );
  }

  Map<String, dynamic> _uveaEye(Map<String, dynamic> uvea, String eyeKey) {
    return Map<String, dynamic>.from(uvea[eyeKey] as Map? ?? {});
  }

  List<String> _uveaAnteriorIssues(Map<String, dynamic> anterior) {
    final issues = <String>[];
    final uvea = _uveaMap(anterior);
    for (final eyeKey in ['RE', 'LE']) {
      final eye = _uveaEye(uvea, eyeKey);
      if (!_hasText(eye['conjunctiva'])) {
        issues.add('$eyeKey conjunctiva');
      } else if (eye['conjunctiva'] == 'Other' &&
          !_hasText(eye['conjunctiva_other'])) {
        issues.add('$eyeKey conjunctiva other');
      }
      if (eye['corneal_keratitis'] is! bool) {
        issues.add('$eyeKey keratitis');
      }
      if (!_hasText(eye['kps_type'])) {
        issues.add('$eyeKey KPs type');
      }
      if (!_hasText(eye['kps_distribution'])) {
        issues.add('$eyeKey KPs distribution');
      }
      if (!_hasText(eye['ac_cells'])) {
        issues.add('$eyeKey AC cells');
      }
      if (!_hasText(eye['flare'])) {
        issues.add('$eyeKey flare');
      }
      if (eye['fm'] is! bool) {
        issues.add('$eyeKey FM');
      }
      if (eye['hypopyon'] is! bool) {
        issues.add('$eyeKey hypopyon');
      } else if (eye['hypopyon'] == true &&
          !_hasText(eye['hypopyon_height_mm'])) {
        issues.add('$eyeKey hypopyon height');
      }
      if (!_hasText(eye['glaucoma'])) {
        issues.add('$eyeKey glaucoma');
      } else if (eye['glaucoma'] == 'Other' &&
          !_hasText(eye['glaucoma_other'])) {
        issues.add('$eyeKey glaucoma other');
      }
      if (!_hasText(eye['lens_status'])) {
        issues.add('$eyeKey lens status');
      }
    }
    return issues;
  }

  List<String> _uveaFundusIssues(Map<String, dynamic> fundus) {
    final issues = <String>[];
    final uvea = _uveaMap(fundus);
    for (final eyeKey in ['RE', 'LE']) {
      final eye = _uveaEye(uvea, eyeKey);
      if (!_hasText(eye['background_retinitis'])) {
        issues.add('$eyeKey retinitis');
      }
      if (!_hasText(eye['background_choroiditis'])) {
        issues.add('$eyeKey choroiditis');
      }
      if (!_hasText(eye['background_vasculitis'])) {
        issues.add('$eyeKey vasculitis');
      }
      if (eye['background_snowbanking'] is! bool) {
        issues.add('$eyeKey snowbanking');
      }
      if (eye['background_snowballing'] is! bool) {
        issues.add('$eyeKey snowballing');
      }
      if (eye['background_exudative_rd'] is! bool) {
        issues.add('$eyeKey exudative RD');
      }
      if (eye['macula_cme'] is! bool) {
        issues.add('$eyeKey macula CME');
      }
      if (eye['macula_exudates'] is! bool) {
        issues.add('$eyeKey macula exudates');
      }
    }
    return issues;
  }

  bool _uveaLocationComplete(Map<String, dynamic> fundus) {
    final locations = _uveaLocationMap(fundus);
    for (final eyeKey in ['RE', 'LE']) {
      final value = locations[eyeKey];
      if (value == null || value.toString().trim().isEmpty) return false;
    }
    return true;
  }

  bool _hasText(dynamic value) {
    if (value == null) return false;
    return value.toString().trim().isNotEmpty;
  }

  String _normalOptionForFundus(FundusSection section) {
    const normalMap = {
      'media': 'Clear',
      'optic_disc': 'Normal',
      'vessels': 'Normal',
      'background_retina': 'Normal',
      'macula': 'Present',
    };
    final mapped = normalMap[section.key];
    if (mapped != null && section.options.contains(mapped)) {
      return mapped;
    }
    if (section.options.contains('Normal')) return 'Normal';
    return section.options.isNotEmpty ? section.options.first : 'Normal';
  }

  bool _isDescriptiveOption(String option) {
    final normalized = option.toLowerCase();
    return normalized.contains('descriptive') ||
        normalized.contains('decriptive');
  }

  Future<void> _saveCase(ClinicalCaseWizardState wizard, String status) async {
    if (!_validateStep(wizard: wizard, showErrors: true)) return;
    try {
      final id = await ref
          .read(clinicalCaseWizardProvider.notifier)
          .save(status: status);
      // Invalidate providers to refresh the list
      ref.invalidate(clinicalCaseListProvider);
      ref.invalidate(clinicalCaseListByKeywordProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'draft'
                ? 'Case saved as draft.'
                : 'Case submitted successfully.',
          ),
        ),
      );
      context.go('/cases/$id');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save case: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  List<String> _parseDiagnoses(String raw) {
    final parts = raw.split(',');
    final normalized = <String>[];
    for (final part in parts) {
      final cleaned = part.trim();
      if (cleaned.isEmpty) continue;
      final exists = normalized.any(
        (e) => e.toLowerCase() == cleaned.toLowerCase(),
      );
      if (!exists) normalized.add(cleaned);
    }
    return normalized;
  }
}
