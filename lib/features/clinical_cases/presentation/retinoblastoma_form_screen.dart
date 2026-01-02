import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/clinical_cases_controller.dart';
import '../data/clinical_cases_repository.dart';

class RetinoblastomaScreeningFormScreen extends ConsumerStatefulWidget {
  const RetinoblastomaScreeningFormScreen({super.key, this.caseId});

  final String? caseId;

  @override
  ConsumerState<RetinoblastomaScreeningFormScreen> createState() =>
      _RetinoblastomaScreeningFormScreenState();
}

class _RetinoblastomaScreeningFormScreenState
    extends ConsumerState<RetinoblastomaScreeningFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _uidController = TextEditingController();
  final _mrnController = TextEditingController();
  final _anteriorRemarksReController = TextEditingController();
  final _anteriorRemarksLeController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _remarksController = TextEditingController();
  final _dateController = TextEditingController();
  final _regressionPatternController = TextEditingController();
  final _treatmentOtherController = TextEditingController();
  final _sittingsController = TextEditingController();

  final _fundusRe = <String, TextEditingController>{};
  final _fundusLe = <String, TextEditingController>{};

  DateTime? _examDate;
  String? _gender;
  bool? _vitreousSeedings;
  bool? _retinalDetachment;
  String? _group;
  final Set<String> _treatmentGiven = {};

  static const _treatmentOptions = [
    'TTT',
    'Cryo',
    'Laser',
    'Others',
  ];

  static const _fundusFields = [
    _FundusField('media', 'Media'),
    _FundusField('optic_disc', 'Optic disc'),
    _FundusField('vessels', 'Vessels'),
    _FundusField('background_retina', 'Background'),
    _FundusField('macula', 'Macula'),
  ];

  @override
  void initState() {
    super.initState();
    for (final field in _fundusFields) {
      _fundusRe[field.key] = TextEditingController();
      _fundusLe[field.key] = TextEditingController();
    }
    if (widget.caseId != null) {
      _loadCase();
    }
  }

  Future<void> _loadCase() async {
    final c = await ref.read(clinicalCaseDetailProvider(widget.caseId!).future);
    _patientNameController.text = c.patientName;
    _ageController.text = c.patientAge.toString();
    _uidController.text = c.uidNumber;
    _mrnController.text = c.mrNumber;
    _gender = c.patientGender;
    _examDate = c.dateOfExamination;
    _dateController.text = _formatDate(c.dateOfExamination);
    _diagnosisController.text = c.diagnosis;
    _remarksController.text = c.management ?? '';
    _anteriorRemarksReController.text =
        _extractEyeRemarks(c.anteriorSegment, 'RE') ?? '';
    _anteriorRemarksLeController.text =
        _extractEyeRemarks(c.anteriorSegment, 'LE') ?? '';
    _prefillRetinoblastoma(c.anteriorSegment);
    _prefillFundus(c.fundus);
    setState(() {});
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _ageController.dispose();
    _uidController.dispose();
    _mrnController.dispose();
    _anteriorRemarksReController.dispose();
    _anteriorRemarksLeController.dispose();
    _diagnosisController.dispose();
    _remarksController.dispose();
    _dateController.dispose();
    _regressionPatternController.dispose();
    _treatmentOtherController.dispose();
    _sittingsController.dispose();
    for (final c in _fundusRe.values) {
      c.dispose();
    }
    for (final c in _fundusLe.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mutation = ref.watch(clinicalCaseMutationProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.caseId == null
            ? 'Retinoblastoma Screening'
            : 'Edit Retinoblastoma Screening'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildText(
                controller: _patientNameController,
                label: 'Patient name',
                validator: _required,
              ),
              _buildText(
                controller: _ageController,
                label: 'Age',
                validator: _required,
                keyboardType: TextInputType.number,
              ),
              _buildText(
                controller: _uidController,
                label: 'UID',
                validator: _required,
              ),
              _buildGenderDropdown(),
              _buildText(
                controller: _mrnController,
                label: 'MRN',
                validator: _required,
              ),
              _buildDateField(),
              _buildText(
                controller: _anteriorRemarksReController,
                label: 'Anterior segment remarks (RE)',
                validator: _required,
              ),
              _buildText(
                controller: _anteriorRemarksLeController,
                label: 'Anterior segment remarks (LE)',
                validator: _required,
              ),
              const SizedBox(height: 12),
              const Text(
                'Fundus Examination',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Expanded(
                    child: Text(
                      'RE',
                      style: TextStyle(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'LE',
                      style: TextStyle(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._fundusFields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildFundusField(
                          controller: _fundusRe[field.key]!,
                          label: field.label,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFundusField(
                          controller: _fundusLe[field.key]!,
                          label: field.label,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Images',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (widget.caseId == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Save the case first to upload images.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: widget.caseId == null
                    ? null
                    : () => context.push('/cases/${widget.caseId}/media'),
                icon: const Icon(Icons.image_outlined),
                label: const Text('Upload Images'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Retinoblastoma details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildYesNoDropdown(
                label: 'Vitreous seedings',
                value: _vitreousSeedings,
                onChanged: (value) => setState(() => _vitreousSeedings = value),
              ),
              _buildYesNoDropdown(
                label: 'Retinal detachment',
                value: _retinalDetachment,
                onChanged: (value) => setState(() => _retinalDetachment = value),
              ),
              _buildGroupDropdown(),
              _buildText(
                controller: _regressionPatternController,
                label: 'Regression pattern',
              ),
              const SizedBox(height: 8),
              const Text(
                'Treatment given',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _treatmentOptions.map((option) {
                  final selected = _treatmentGiven.contains(option);
                  return FilterChip(
                    label: Text(option),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _treatmentGiven.add(option);
                        } else {
                          _treatmentGiven.remove(option);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              if (_treatmentGiven.contains('Others'))
                _buildText(
                  controller: _treatmentOtherController,
                  label: 'Treatment (other)',
                  validator: _minOtherValidator,
                ),
              _buildText(
                controller: _sittingsController,
                label: 'No. of sittings',
                keyboardType: TextInputType.number,
                validator: _sittingsValidator,
              ),
              _buildText(
                controller: _diagnosisController,
                label: 'Diagnosis',
                validator: _required,
              ),
              _buildText(
                controller: _remarksController,
                label: 'Remarks',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: mutation.isLoading ? null : _save,
                    child: mutation.isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(color: Colors.black),
                          ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildText({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: validator,
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildYesNoDropdown({
    required String label,
    required bool? value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<bool>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: const [
          DropdownMenuItem(value: true, child: Text('Yes')),
          DropdownMenuItem(value: false, child: Text('No')),
        ],
        validator: (v) => v == null ? 'Required' : null,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildGroupDropdown() {
    const groups = ['A', 'B', 'C', 'D', 'E'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: _group,
        decoration: const InputDecoration(labelText: 'Group'),
        items: groups
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        onChanged: (v) => setState(() => _group = v),
      ),
    );
  }

  Widget _buildFundusField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: _required,
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: _gender,
        decoration: const InputDecoration(labelText: 'Gender'),
        items: const [
          DropdownMenuItem(value: 'male', child: Text('Male')),
          DropdownMenuItem(value: 'female', child: Text('Female')),
        ],
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        onChanged: (v) => setState(() => _gender = v),
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _dateController,
        readOnly: true,
        decoration: const InputDecoration(labelText: 'Date of examination'),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _examDate ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            setState(() {
              _examDate = picked;
              _dateController.text = _formatDate(picked);
            });
          }
        },
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _minOtherValidator(String? value) {
    if (!_treatmentGiven.contains('Others')) return null;
    if (value == null || value.trim().length < 3) {
      return 'Please specify (min 3 chars)';
    }
    return null;
  }

  String? _sittingsValidator(String? value) {
    if (_treatmentGiven.isEmpty) return null;
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 1) {
      return 'Enter a valid number';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final age = int.tryParse(_ageController.text.trim());
    if (age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Age must be a number')),
      );
      return;
    }
    if (_examDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Date of examination is required')),
      );
      return;
    }

    final data = <String, dynamic>{
      'date_of_examination': _formatDate(_examDate!),
      'patient_name': _patientNameController.text.trim(),
      'uid_number': _uidController.text.trim(),
      'mr_number': _mrnController.text.trim(),
      'patient_gender': _gender,
      'patient_age': age,
      'chief_complaint': 'Retinoblastoma screening',
      'complaint_duration_value': 1,
      'complaint_duration_unit': 'days',
      'systemic_history': <dynamic>[],
      'diagnosis': _diagnosisController.text.trim(),
      'keywords': _buildKeywords(),
      'anterior_segment': _buildAnteriorSegment(),
      'fundus': _buildFundus(),
      'management': _remarksController.text.trim(),
      'status': 'draft',
    };

    try {
      final mutation = ref.read(clinicalCaseMutationProvider.notifier);
      if (widget.caseId == null) {
        final id = await mutation.create(data);
        if (mounted) {
          context.go('/cases/retinoblastoma/$id');
        }
      } else {
        await mutation.update(widget.caseId!, data);
        if (mounted) {
          context.go('/cases/retinoblastoma/${widget.caseId}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  List<String> _buildKeywords() {
    final keywords = <String>['retinoblastoma'];
    final diagnosis = _diagnosisController.text.trim();
    if (diagnosis.isNotEmpty &&
        keywords.every((k) => k.toLowerCase() != diagnosis.toLowerCase())) {
      keywords.add(diagnosis);
    }
    return keywords.take(5).toList();
  }

  Map<String, dynamic> _buildAnteriorSegment() {
    final reRemarks = _anteriorRemarksReController.text.trim();
    final leRemarks = _anteriorRemarksLeController.text.trim();
    return {
      'remarks': '',
      'RE': {'remarks': reRemarks},
      'LE': {'remarks': leRemarks},
      'retinoblastoma': {
        'vitreous_seedings': _vitreousSeedings,
        'retinal_detachment': _retinalDetachment,
        'group': _group,
        'regression_pattern': _regressionPatternController.text.trim(),
        'treatment_given': _treatmentGiven.toList(),
        'treatment_other': _treatmentOtherController.text.trim(),
        'sittings': int.tryParse(_sittingsController.text.trim()),
      },
    };
  }

  Map<String, dynamic> _buildFundus() {
    Map<String, dynamic> buildEye(Map<String, TextEditingController> ctrls) {
      final data = <String, dynamic>{};
      for (final field in _fundusFields) {
        final value = ctrls[field.key]!.text.trim();
        data[field.key] = {
          'selected': value.isEmpty ? <String>[] : <String>[value],
          'descriptions': <String, String>{},
        };
      }
      return data;
    }

    return {
      'RE': buildEye(_fundusRe),
      'LE': buildEye(_fundusLe),
      'remarks': _remarksController.text.trim(),
    };
  }

  void _prefillFundus(Map<String, dynamic>? fundus) {
    if (fundus == null || fundus.isEmpty) return;
    for (final eyeKey in ['RE', 'LE']) {
      final eye = Map<String, dynamic>.from(fundus[eyeKey] as Map? ?? {});
      final target = eyeKey == 'RE' ? _fundusRe : _fundusLe;
      for (final field in _fundusFields) {
        final section = Map<String, dynamic>.from(eye[field.key] as Map? ?? {});
        final selected =
            (section['selected'] as List?)?.cast<String>() ?? const <String>[];
        if (selected.isNotEmpty) {
          target[field.key]?.text = selected.first;
        }
      }
    }
  }

  void _prefillRetinoblastoma(Map<String, dynamic>? anterior) {
    if (anterior == null || anterior.isEmpty) return;
    final rb =
        Map<String, dynamic>.from(anterior['retinoblastoma'] as Map? ?? {});
    if (rb.isEmpty) return;
    final treatments =
        (rb['treatment_given'] as List?)?.cast<String>() ?? const <String>[];
    _treatmentGiven
      ..clear()
      ..addAll(treatments);
    _vitreousSeedings = rb['vitreous_seedings'] as bool?;
    _retinalDetachment = rb['retinal_detachment'] as bool?;
    _group = rb['group'] as String?;
    _regressionPatternController.text =
        (rb['regression_pattern'] as String?) ?? '';
    _treatmentOtherController.text =
        (rb['treatment_other'] as String?) ?? '';
    final sittings = rb['sittings'];
    if (sittings != null) {
      _sittingsController.text = sittings.toString();
    }
  }

  String? _extractEyeRemarks(Map<String, dynamic>? anterior, String eyeKey) {
    if (anterior == null || anterior.isEmpty) return null;
    final eye = Map<String, dynamic>.from(anterior[eyeKey] as Map? ?? {});
    final remarks = (eye['remarks'] as String?) ?? '';
    return remarks.isEmpty ? null : remarks;
  }
}

class _FundusField {
  const _FundusField(this.key, this.label);
  final String key;
  final String label;
}
