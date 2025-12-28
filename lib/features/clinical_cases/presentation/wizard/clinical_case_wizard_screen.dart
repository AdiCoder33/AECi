import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/clinical_case_wizard_controller.dart';
import '../../data/clinical_case_constants.dart';
import 'steps/step1_patient.dart';
import 'steps/step2_complaints.dart';
import 'steps/step3_systemic.dart';
import 'steps/step4_bcva.dart';
import 'steps/step5_iop.dart';
import 'steps/step6_anterior.dart';
import 'steps/step7_fundus.dart';
import 'steps/step8_diagnosis_keywords.dart';
import 'widgets/wizard_footer.dart';
import 'widgets/wizard_header.dart';

class ClinicalCaseWizardScreen extends ConsumerStatefulWidget {
  const ClinicalCaseWizardScreen({super.key, this.caseId});

  final String? caseId;

  @override
  ConsumerState<ClinicalCaseWizardScreen> createState() =>
      _ClinicalCaseWizardScreenState();
}

class _ClinicalCaseWizardScreenState
    extends ConsumerState<ClinicalCaseWizardScreen> {
  final _formKeys = List.generate(8, (_) => GlobalKey<FormState>());
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
  final _keywordsController = TextEditingController();
  int _stepIndex = 0;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    _bindControllers();
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
    _durationController.text =
        state.complaintDurationValue?.toString() ?? '';
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
    ref.listen<ClinicalCaseWizardState>(clinicalCaseWizardProvider,
        (previous, next) {
      if (next.caseId != null && !_prefilled && !next.isLoading) {
        _prefillFromState(next);
      }
    });

    if (wizard.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final titles = [
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
        onGenderChanged: (value) =>
            notifier.update(patientGender: value),
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
          onSelectionChanged: (next) =>
              notifier.update(systemicHistory: next),
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
      Step6Anterior(
        formKey: _formKeys[5],
        anterior: wizard.anteriorSegment,
        onChanged: (value) => notifier.update(anteriorSegment: value),
        onLidsFindingsChanged: (eye, findings) =>
            notifier.setLidsFindings(eye: eye, findings: findings),
        onLidsOtherNotesChanged: (eye, notes) =>
            notifier.setLidsOtherNotes(eye: eye, notes: notes),
      ),
      Step7Fundus(
        formKey: _formKeys[6],
        fundus: wizard.fundus,
        onChanged: (value) => notifier.update(fundus: value),
      ),
      Step8DiagnosisKeywords(
        formKey: _formKeys[7],
        diagnosisController: _diagnosisController,
        keywordsController: _keywordsController,
        keywords: wizard.keywords,
        onKeywordsChanged: (value) => notifier.update(keywords: value),
      ),
    ];

    final isLast = _stepIndex == steps.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Case Wizard'),
      ),
      body: Column(
        children: [
          WizardHeader(
            step: _stepIndex + 1,
            total: steps.length,
            title: titles[_stepIndex],
          ),
          Expanded(
            child: IndexedStack(
              index: _stepIndex,
              children: steps,
            ),
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
      _stepIndex = (_stepIndex - 1).clamp(0, 7);
    });
  }

  void _goNext() {
    if (!_validateStep(showErrors: true)) return;
    setState(() {
      _stepIndex = (_stepIndex + 1).clamp(0, 7);
    });
  }

  bool _canProceed(ClinicalCaseWizardState wizard) {
    return _isStepComplete(wizard);
  }

  bool _validateStep({ClinicalCaseWizardState? wizard, bool showErrors = false}) {
    final ClinicalCaseWizardState state =
        wizard ?? ref.read(clinicalCaseWizardProvider);
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

    if (_stepIndex == 5) {
      final issues = _anteriorIssues(state.anteriorSegment);
      final lidsIssues = _lidsIssues(state.anteriorSegment);
      if (issues.isNotEmpty) {
        if (showErrors) {
          _showError('Add notes for abnormal anterior findings.');
        }
        return false;
      }
      if (lidsIssues.isNotEmpty) {
        if (showErrors) {
          _showError('Please complete lids findings for both eyes.');
        }
        return false;
      }
    }

    if (_stepIndex == 6) {
      final issues = _fundusIssues(state.fundus);
      if (issues.isNotEmpty) {
        if (showErrors) {
          _showError('Please complete all fundus fields for both eyes.');
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

    return true;
  }

  bool _isStepComplete(ClinicalCaseWizardState state) {
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
        return _anteriorIssues(state.anteriorSegment).isEmpty &&
            _lidsIssues(state.anteriorSegment).isEmpty;
      case 6:
        return _fundusIssues(state.fundus).isEmpty;
      case 7:
        return _diagnosisController.text.trim().isNotEmpty &&
            state.keywords.isNotEmpty &&
            state.keywords.length <= 5;
      default:
        return true;
    }
  }

  List<String> _anteriorIssues(Map<String, dynamic> anterior) {
    final issues = <String>[];
    for (final eyeKey in ['RE', 'LE']) {
      final eye = Map<String, dynamic>.from(anterior[eyeKey] as Map? ?? {});
      for (final field in anteriorSegments) {
        final data = Map<String, dynamic>.from(eye[field] as Map? ?? {});
        final status = (data['status'] as String?) ?? 'normal';
        final notes = (data['notes'] as String?) ?? '';
        if (status == 'abnormal' && notes.trim().isEmpty) {
          issues.add('$eyeKey $field');
        }
      }
    }
    return issues;
  }

  List<String> _lidsIssues(Map<String, dynamic> anterior) {
    final issues = <String>[];
    for (final eyeKey in ['RE', 'LE']) {
      final eye = Map<String, dynamic>.from(anterior[eyeKey] as Map? ?? {});
      final findings =
          (eye['lids_findings'] as List?)?.cast<String>() ?? <String>[];
      final otherNotes = (eye['lids_other_notes'] as String?) ?? '';
      if (findings.isEmpty) {
        issues.add('$eyeKey lids required');
        continue;
      }
      if (findings.contains('Normal') && findings.length > 1) {
        issues.add('$eyeKey lids normal exclusive');
      }
      if (findings.contains('Other') && otherNotes.trim().length < 3) {
        issues.add('$eyeKey lids other notes');
      }
    }
    return issues;
  }

  List<String> _fundusIssues(Map<String, dynamic> fundus) {
    final issues = <String>[];
    for (final eyeKey in ['RE', 'LE']) {
      final eye = Map<String, dynamic>.from(fundus[eyeKey] as Map? ?? {});
      for (final field in fundusFields) {
        final value = eye[field] as String? ?? '';
        if (value.isEmpty) {
          issues.add('$eyeKey $field');
        }
      }
    }
    return issues;
  }

  Future<void> _saveCase(ClinicalCaseWizardState wizard, String status) async {
    if (!_validateStep(wizard: wizard, showErrors: true)) return;
    try {
      final id = await ref
          .read(clinicalCaseWizardProvider.notifier)
          .save(status: status);
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}
