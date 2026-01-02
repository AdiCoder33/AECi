import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/clinical_cases_controller.dart';
import '../data/clinical_cases_repository.dart';

class RopScreeningFormScreen extends ConsumerStatefulWidget {
  const RopScreeningFormScreen({super.key, this.caseId});

  final String? caseId;

  @override
  ConsumerState<RopScreeningFormScreen> createState() =>
      _RopScreeningFormScreenState();
}

class _RopScreeningFormScreenState extends ConsumerState<RopScreeningFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _uidController = TextEditingController();
  final _mrnController = TextEditingController();
  final _gestationalAgeController = TextEditingController();
  final _postConceptionAgeController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _remarksController = TextEditingController();
  final _dateController = TextEditingController();

  final _anteriorRe = <String, TextEditingController>{};
  final _anteriorLe = <String, TextEditingController>{};
  final _fundusRe = <String, TextEditingController>{};
  final _fundusLe = <String, TextEditingController>{};

  DateTime? _examDate;
  String? _gender;

  String? _zoneRe;
  String? _zoneLe;
  String? _stageRe;
  String? _stageLe;
  bool? _plusRe;
  bool? _plusLe;
  bool? _agropRe;
  bool? _agropLe;

  static const _anteriorFields = [
    _FundusField('pupil', 'Pupil'),
    _FundusField('lens', 'Lens'),
  ];

  static const _fundusFields = [
    _FundusField('media', 'Media'),
    _FundusField('optic_disc', 'Optic disc'),
    _FundusField('vessels', 'Vessels'),
    _FundusField('background_retina', 'Background'),
    _FundusField('macula', 'Macula'),
  ];

  static const _zoneOptions = ['1', '2', '3'];
  static const _stageOptions = ['1', '2', '3', '4a', '4b', '5'];

  @override
  void initState() {
    super.initState();
    for (final field in _anteriorFields) {
      _anteriorRe[field.key] = TextEditingController();
      _anteriorLe[field.key] = TextEditingController();
    }
    for (final field in _fundusFields) {
      _fundusRe[field.key] = TextEditingController();
      _fundusLe[field.key] = TextEditingController();
    }
    if (widget.caseId != null) {
      _loadCase();
    }
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _uidController.dispose();
    _mrnController.dispose();
    _gestationalAgeController.dispose();
    _postConceptionAgeController.dispose();
    _diagnosisController.dispose();
    _remarksController.dispose();
    _dateController.dispose();
    for (final c in _anteriorRe.values) {
      c.dispose();
    }
    for (final c in _anteriorLe.values) {
      c.dispose();
    }
    for (final c in _fundusRe.values) {
      c.dispose();
    }
    for (final c in _fundusLe.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCase() async {
    final c = await ref.read(clinicalCaseDetailProvider(widget.caseId!).future);
    _patientNameController.text = c.patientName;
    _uidController.text = c.uidNumber;
    _mrnController.text = c.mrNumber;
    _gender = c.patientGender;
    _examDate = c.dateOfExamination;
    _dateController.text = _formatDate(c.dateOfExamination);
    _diagnosisController.text = c.diagnosis;
    _remarksController.text = c.management ?? '';

    final meta = Map<String, dynamic>.from(c.fundus?['rop_meta'] as Map? ?? {});
    _gestationalAgeController.text =
        meta['gestational_age']?.toString() ?? '';
    _postConceptionAgeController.text =
        meta['post_conceptional_age']?.toString() ?? '';
    _zoneRe = (meta['zone'] as Map?)?['RE']?.toString();
    _zoneLe = (meta['zone'] as Map?)?['LE']?.toString();
    _stageRe = (meta['stage'] as Map?)?['RE']?.toString();
    _stageLe = (meta['stage'] as Map?)?['LE']?.toString();
    _plusRe = (meta['plus_disease'] as Map?)?['RE'] as bool?;
    _plusLe = (meta['plus_disease'] as Map?)?['LE'] as bool?;
    _agropRe = (meta['agrop'] as Map?)?['RE'] as bool?;
    _agropLe = (meta['agrop'] as Map?)?['LE'] as bool?;

    _prefillEyeText(c.anteriorSegment, 'RE', _anteriorRe);
    _prefillEyeText(c.anteriorSegment, 'LE', _anteriorLe);
    _prefillEyeText(c.fundus, 'RE', _fundusRe);
    _prefillEyeText(c.fundus, 'LE', _fundusLe);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mutation = ref.watch(clinicalCaseMutationProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.caseId == null
            ? 'ROP Screening'
            : 'Edit ROP Screening'),
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
                controller: _uidController,
                label: 'UID',
                validator: _required,
              ),
              _buildText(
                controller: _mrnController,
                label: 'MR No.',
                validator: _required,
              ),
              _buildGenderDropdown(),
              _buildText(
                controller: _gestationalAgeController,
                label: 'Gestational age (weeks)',
                validator: _required,
                keyboardType: TextInputType.number,
              ),
              _buildText(
                controller: _postConceptionAgeController,
                label: 'Post conceptional age (weeks)',
                validator: _required,
                keyboardType: TextInputType.number,
              ),
              _buildDateField(),
              const SizedBox(height: 12),
              const Text(
                'Anterior Segment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildEyeHeader(),
              const SizedBox(height: 8),
              ..._anteriorFields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildEyeRow(
                    label: field.label,
                    reController: _anteriorRe[field.key]!,
                    leController: _anteriorLe[field.key]!,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Fundus Examination',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildEyeHeader(),
              const SizedBox(height: 8),
              ..._fundusFields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildEyeRow(
                    label: field.label,
                    reController: _fundusRe[field.key]!,
                    leController: _fundusLe[field.key]!,
                  ),
                ),
              ),
              _buildText(
                controller: _diagnosisController,
                label: 'Diagnosis',
                validator: _required,
              ),
              const SizedBox(height: 8),
              _buildEyeSelectionRow(
                label: 'Zone',
                options: _zoneOptions,
                valueRe: _zoneRe,
                valueLe: _zoneLe,
                onChangedRe: (v) => setState(() => _zoneRe = v),
                onChangedLe: (v) => setState(() => _zoneLe = v),
              ),
              const SizedBox(height: 8),
              _buildEyeSelectionRow(
                label: 'Stage',
                options: _stageOptions,
                valueRe: _stageRe,
                valueLe: _stageLe,
                onChangedRe: (v) => setState(() => _stageRe = v),
                onChangedLe: (v) => setState(() => _stageLe = v),
              ),
              const SizedBox(height: 8),
              _buildEyeToggleRow(
                label: 'Plus disease',
                valueRe: _plusRe,
                valueLe: _plusLe,
                onChangedRe: (v) => setState(() => _plusRe = v),
                onChangedLe: (v) => setState(() => _plusLe = v),
              ),
              const SizedBox(height: 8),
              _buildEyeToggleRow(
                label: 'AGROP',
                valueRe: _agropRe,
                valueLe: _agropLe,
                onChangedRe: (v) => setState(() => _agropRe = v),
                onChangedLe: (v) => setState(() => _agropLe = v),
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
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

  Widget _buildEyeHeader() {
    return Row(
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
    );
  }

  Widget _buildEyeRow({
    required String label,
    required TextEditingController reController,
    required TextEditingController leController,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: reController,
            decoration: InputDecoration(labelText: label),
            validator: _required,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: leController,
            decoration: InputDecoration(labelText: label),
            validator: _required,
          ),
        ),
      ],
    );
  }

  Widget _buildEyeSelectionRow({
    required String label,
    required List<String> options,
    required String? valueRe,
    required String? valueLe,
    required ValueChanged<String> onChangedRe,
    required ValueChanged<String> onChangedLe,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 6,
                children: options
                    .map(
                      (o) => ChoiceChip(
                        label: Text(o),
                        selected: valueRe == o,
                        onSelected: (_) => onChangedRe(o),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 6,
                children: options
                    .map(
                      (o) => ChoiceChip(
                        label: Text(o),
                        selected: valueLe == o,
                        onSelected: (_) => onChangedLe(o),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEyeToggleRow({
    required String label,
    required bool? valueRe,
    required bool? valueLe,
    required ValueChanged<bool> onChangedRe,
    required ValueChanged<bool> onChangedLe,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('Yes'),
                    selected: valueRe == true,
                    onSelected: (_) => onChangedRe(true),
                  ),
                  ChoiceChip(
                    label: const Text('No'),
                    selected: valueRe == false,
                    onSelected: (_) => onChangedRe(false),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('Yes'),
                    selected: valueLe == true,
                    onSelected: (_) => onChangedLe(true),
                  ),
                  ChoiceChip(
                    label: const Text('No'),
                    selected: valueLe == false,
                    onSelected: (_) => onChangedLe(false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  bool _validateRopSelections() {
    if (_zoneRe == null ||
        _zoneLe == null ||
        _stageRe == null ||
        _stageLe == null ||
        _plusRe == null ||
        _plusLe == null ||
        _agropRe == null ||
        _agropLe == null) {
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_examDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Date of examination is required')),
      );
      return;
    }
    if (!_validateRopSelections()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete ROP assessment selections')),
      );
      return;
    }
    final gestational = int.tryParse(_gestationalAgeController.text.trim());
    final postConception =
        int.tryParse(_postConceptionAgeController.text.trim());
    if (gestational == null || postConception == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gestational ages must be numbers')),
      );
      return;
    }

    final data = <String, dynamic>{
      'date_of_examination': _formatDate(_examDate!),
      'patient_name': _patientNameController.text.trim(),
      'uid_number': _uidController.text.trim(),
      'mr_number': _mrnController.text.trim(),
      'patient_gender': _gender,
      'patient_age': postConception,
      'chief_complaint': 'ROP screening',
      'complaint_duration_value': 1,
      'complaint_duration_unit': 'days',
      'systemic_history': <dynamic>[],
      'diagnosis': _diagnosisController.text.trim(),
      'keywords': _buildKeywords(),
      'anterior_segment': _buildAnteriorSegment(),
      'fundus': _buildFundus(
        gestationalAge: gestational,
        postConceptionAge: postConception,
      ),
      'management': _remarksController.text.trim(),
      'status': 'draft',
    };

    try {
      final mutation = ref.read(clinicalCaseMutationProvider.notifier);
      if (widget.caseId == null) {
        final id = await mutation.create(data);
        if (mounted) {
          context.go('/cases/$id');
        }
      } else {
        await mutation.update(widget.caseId!, data);
        if (mounted) {
          context.go('/cases/${widget.caseId}');
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
    final keywords = <String>['rop'];
    final diagnosis = _diagnosisController.text.trim();
    if (diagnosis.isNotEmpty &&
        keywords.every((k) => k.toLowerCase() != diagnosis.toLowerCase())) {
      keywords.add(diagnosis);
    }
    return keywords.take(5).toList();
  }

  Map<String, dynamic> _buildAnteriorSegment() {
    Map<String, dynamic> buildEye(Map<String, TextEditingController> ctrls) {
      final data = <String, dynamic>{};
      for (final field in _anteriorFields) {
        final value = ctrls[field.key]!.text.trim();
        data[field.key] = {
          'selected': value.isEmpty ? <String>[] : <String>[value],
          'descriptions': <String, String>{},
        };
      }
      return data;
    }

    return {
      'RE': buildEye(_anteriorRe),
      'LE': buildEye(_anteriorLe),
    };
  }

  Map<String, dynamic> _buildFundus({
    required int gestationalAge,
    required int postConceptionAge,
  }) {
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
      'rop_meta': {
        'gestational_age': gestationalAge,
        'post_conceptional_age': postConceptionAge,
        'zone': {'RE': _zoneRe, 'LE': _zoneLe},
        'stage': {'RE': _stageRe, 'LE': _stageLe},
        'plus_disease': {'RE': _plusRe, 'LE': _plusLe},
        'agrop': {'RE': _agropRe, 'LE': _agropLe},
      },
      'remarks': _remarksController.text.trim(),
    };
  }

  void _prefillEyeText(
    Map<String, dynamic>? payload,
    String eyeKey,
    Map<String, TextEditingController> target,
  ) {
    if (payload == null || payload.isEmpty) return;
    final eye = Map<String, dynamic>.from(payload[eyeKey] as Map? ?? {});
    for (final field in target.keys) {
      final section = Map<String, dynamic>.from(eye[field] as Map? ?? {});
      final selected =
          (section['selected'] as List?)?.cast<String>() ?? const <String>[];
      if (selected.isNotEmpty) {
        target[field]?.text = selected.first;
      }
    }
  }
}

class _FundusField {
  const _FundusField(this.key, this.label);
  final String key;
  final String label;
}
