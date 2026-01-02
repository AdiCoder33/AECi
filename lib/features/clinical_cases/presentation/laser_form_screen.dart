import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/clinical_cases_controller.dart';
import '../data/clinical_case_constants.dart';

class LaserFormScreen extends ConsumerStatefulWidget {
  const LaserFormScreen({super.key, this.caseId});

  final String? caseId;

  @override
  ConsumerState<LaserFormScreen> createState() => _LaserFormScreenState();
}

class _LaserFormScreenState extends ConsumerState<LaserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _uidController = TextEditingController();
  final _mrnController = TextEditingController();
  final _ageController = TextEditingController();
  final _bcvaReController = TextEditingController();
  final _bcvaLeController = TextEditingController();
  final _diagnosisReController = TextEditingController();
  final _diagnosisLeController = TextEditingController();
  final _powerController = TextEditingController();
  final _durationController = TextEditingController();
  final _intervalController = TextEditingController();
  final _spotSizeController = TextEditingController();
  final _spotSpacingController = TextEditingController();

  DateTime? _examDate;
  String? _gender;
  String? _laserTypeRe;
  String? _laserTypeLe;
  String? _pattern;
  String? _burnIntensity;

  static const _laserTypes = [
    'Pan retinal photocoagulation',
    'Grid Laser',
    'Focal Laser',
    'Barrage Laser',
    'Subthreshold micropulse Laser',
    'Nil',
  ];

  static const _patterns = ['2x2', '3x3', '4x4', '5x5', '7x7'];

  static const _burnIntensities = [
    'Grade 1 (tight)',
    'Grade 2 (mild)',
    'Grade 3 (moderate)',
    'Grade 4 (heavy)',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.caseId != null) {
      _loadCase();
    }
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _uidController.dispose();
    _mrnController.dispose();
    _ageController.dispose();
    _bcvaReController.dispose();
    _bcvaLeController.dispose();
    _diagnosisReController.dispose();
    _diagnosisLeController.dispose();
    _powerController.dispose();
    _durationController.dispose();
    _intervalController.dispose();
    _spotSizeController.dispose();
    _spotSpacingController.dispose();
    super.dispose();
  }

  Future<void> _loadCase() async {
    final c = await ref.read(clinicalCaseDetailProvider(widget.caseId!).future);
    _patientNameController.text = c.patientName;
    _uidController.text = c.uidNumber;
    _mrnController.text = c.mrNumber;
    _ageController.text = c.patientAge.toString();
    _gender = c.patientGender;
    _examDate = c.dateOfExamination;
    _bcvaReController.text = c.bcvaRe ?? '';
    _bcvaLeController.text = c.bcvaLe ?? '';

    final laser =
        Map<String, dynamic>.from(c.anteriorSegment?['laser'] as Map? ?? {});
    final bcva =
        Map<String, dynamic>.from(laser['bcva_pre'] as Map? ?? {});
    final diagnosis =
        Map<String, dynamic>.from(laser['diagnosis'] as Map? ?? {});
    final laserType =
        Map<String, dynamic>.from(laser['laser_type'] as Map? ?? {});
    final params =
        Map<String, dynamic>.from(laser['parameters'] as Map? ?? {});

    _bcvaReController.text =
        (bcva['RE'] as String?) ?? _bcvaReController.text;
    _bcvaLeController.text =
        (bcva['LE'] as String?) ?? _bcvaLeController.text;
    _diagnosisReController.text =
        (diagnosis['RE'] as String?) ?? '';
    _diagnosisLeController.text =
        (diagnosis['LE'] as String?) ?? '';
    _laserTypeRe = laserType['RE'] as String?;
    _laserTypeLe = laserType['LE'] as String?;
    _powerController.text = (params['power_mw'] as String?) ?? '';
    _durationController.text = (params['duration_ms'] as String?) ?? '';
    _intervalController.text = (params['interval'] as String?) ?? '';
    _spotSizeController.text = (params['spot_size_um'] as String?) ?? '';
    _pattern = params['pattern'] as String?;
    _spotSpacingController.text = (params['spot_spacing'] as String?) ?? '';
    _burnIntensity = params['burn_intensity'] as String?;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mutation = ref.watch(clinicalCaseMutationProvider);
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.caseId == null ? 'Laser Entry' : 'Edit Laser Entry'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateField(),
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
                label: 'MRN',
                validator: _required,
              ),
              _buildText(
                controller: _ageController,
                label: 'Age',
                validator: _required,
                keyboardType: TextInputType.number,
              ),
              _buildGenderDropdown(),
              const SizedBox(height: 12),
              const Text(
                'BCVA (Pre-laser)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildText(
                      controller: _bcvaReController,
                      label: 'RE',
                      validator: _required,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildText(
                      controller: _bcvaLeController,
                      label: 'LE',
                      validator: _required,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Diagnosis',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildText(
                      controller: _diagnosisReController,
                      label: 'RE',
                      validator: _diagnosisValidator,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildText(
                      controller: _diagnosisLeController,
                      label: 'LE',
                      validator: _diagnosisValidator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Laser type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'RE',
                      value: _laserTypeRe,
                      items: _laserTypes,
                      onChanged: (v) => setState(() => _laserTypeRe = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown(
                      label: 'LE',
                      value: _laserTypeLe,
                      items: _laserTypes,
                      onChanged: (v) => setState(() => _laserTypeLe = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Laser parameters',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildText(
                controller: _powerController,
                label: 'Power (mW)',
                keyboardType: TextInputType.number,
              ),
              _buildText(
                controller: _durationController,
                label: 'Duration (ms)',
                keyboardType: TextInputType.number,
              ),
              _buildText(
                controller: _intervalController,
                label: 'Interval',
              ),
              _buildText(
                controller: _spotSizeController,
                label: 'Spot size (um)',
                keyboardType: TextInputType.number,
              ),
              _buildDropdown(
                label: 'Pattern',
                value: _pattern,
                items: _patterns,
                onChanged: (v) => setState(() => _pattern = v),
              ),
              _buildText(
                controller: _spotSpacingController,
                label: 'Spot spacing',
                keyboardType: TextInputType.number,
              ),
              _buildDropdown(
                label: 'Burn intensity',
                value: _burnIntensity,
                items: _burnIntensities,
                onChanged: (v) => setState(() => _burnIntensity = v),
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: _gender,
        decoration: const InputDecoration(labelText: 'Sex'),
        items: const [
          DropdownMenuItem(value: 'male', child: Text('Male')),
          DropdownMenuItem(value: 'female', child: Text('Female')),
        ],
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        onChanged: (v) => setState(() => _gender = v),
      ),
    );
  }

  Widget _buildDateField() {
    final label = _examDate == null
        ? 'Date of examination'
        : 'Date of examination (${_formatDate(_examDate!)})';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        readOnly: true,
        decoration: InputDecoration(labelText: label),
        validator: (_) => _examDate == null ? 'Required' : null,
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: _examDate ?? now,
            firstDate: DateTime(now.year - 10),
            lastDate: now,
          );
          if (picked != null) {
            setState(() => _examDate = picked);
          }
        },
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _diagnosisValidator(String? value) {
    final re = _diagnosisReController.text.trim();
    final le = _diagnosisLeController.text.trim();
    if (re.isEmpty && le.isEmpty) {
      return 'Required';
    }
    return null;
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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

    final diagnosisRe = _diagnosisReController.text.trim();
    final diagnosisLe = _diagnosisLeController.text.trim();
    final diagnosisSummary = _buildDiagnosisSummary(diagnosisRe, diagnosisLe);

    final data = <String, dynamic>{
      'date_of_examination': _formatDate(_examDate!),
      'patient_name': _patientNameController.text.trim(),
      'uid_number': _uidController.text.trim(),
      'mr_number': _mrnController.text.trim(),
      'patient_gender': _gender,
      'patient_age': age,
      'chief_complaint': 'Laser entry',
      'complaint_duration_value': 1,
      'complaint_duration_unit': complaintUnits.first,
      'systemic_history': <dynamic>[],
      'bcva_re': _bcvaReController.text.trim(),
      'bcva_le': _bcvaLeController.text.trim(),
      'diagnosis': diagnosisSummary,
      'keywords': _buildKeywords(diagnosisSummary),
      'anterior_segment': _buildLaserPayload(),
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

  String _buildDiagnosisSummary(String re, String le) {
    if (re.isNotEmpty && le.isNotEmpty) {
      return 'RE: $re | LE: $le';
    }
    if (re.isNotEmpty) return re;
    if (le.isNotEmpty) return le;
    return 'Laser';
  }

  List<String> _buildKeywords(String diagnosisSummary) {
    final keywords = <String>['laser'];
    final cleaned = diagnosisSummary.trim();
    if (cleaned.isNotEmpty &&
        keywords.every((k) => k.toLowerCase() != cleaned.toLowerCase())) {
      keywords.add(cleaned);
    }
    return keywords.take(5).toList();
  }

  Map<String, dynamic> _buildLaserPayload() {
    return {
      'laser': {
        'bcva_pre': {
          'RE': _bcvaReController.text.trim(),
          'LE': _bcvaLeController.text.trim(),
        },
        'diagnosis': {
          'RE': _diagnosisReController.text.trim(),
          'LE': _diagnosisLeController.text.trim(),
        },
        'laser_type': {
          'RE': _laserTypeRe,
          'LE': _laserTypeLe,
        },
        'parameters': {
          'power_mw': _powerController.text.trim(),
          'duration_ms': _durationController.text.trim(),
          'interval': _intervalController.text.trim(),
          'spot_size_um': _spotSizeController.text.trim(),
          'pattern': _pattern,
          'spot_spacing': _spotSpacingController.text.trim(),
          'burn_intensity': _burnIntensity,
        },
      },
    };
  }
}
