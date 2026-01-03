import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../application/clinical_cases_controller.dart';
import '../data/clinical_case_constants.dart';
import '../data/clinical_cases_repository.dart';

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
  final _powerReController = TextEditingController();
  final _powerLeController = TextEditingController();
  final _durationReController = TextEditingController();
  final _durationLeController = TextEditingController();
  final _intervalReController = TextEditingController();
  final _intervalLeController = TextEditingController();
  final _spotSizeReController = TextEditingController();
  final _spotSizeLeController = TextEditingController();
  final _spotSpacingReController = TextEditingController();
  final _spotSpacingLeController = TextEditingController();
  final _examDateController = TextEditingController();

  DateTime? _examDate;
  String? _gender;
  String? _laserTypeRe;
  String? _laserTypeLe;
  String? _patternRe;
  String? _patternLe;
  String? _burnIntensityRe;
  String? _burnIntensityLe;
  bool _uploadingRe = false;
  bool _uploadingLe = false;
  bool _uploadingVideoRe = false;
  bool _uploadingVideoLe = false;

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
  static const _laserMediaCategory = 'FUNDUS';

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
    _powerReController.dispose();
    _powerLeController.dispose();
    _durationReController.dispose();
    _durationLeController.dispose();
    _intervalReController.dispose();
    _intervalLeController.dispose();
    _spotSizeReController.dispose();
    _spotSizeLeController.dispose();
    _spotSpacingReController.dispose();
    _spotSpacingLeController.dispose();
    _examDateController.dispose();
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
    _examDateController.text = _formatDate(_examDate!);
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

    _bcvaReController.text = _normalizeBcva(
      (bcva['RE'] as String?) ?? _bcvaReController.text,
    );
    _bcvaLeController.text = _normalizeBcva(
      (bcva['LE'] as String?) ?? _bcvaLeController.text,
    );
    _diagnosisReController.text =
        (diagnosis['RE'] as String?) ?? '';
    _diagnosisLeController.text =
        (diagnosis['LE'] as String?) ?? '';
    _laserTypeRe = laserType['RE'] as String?;
    _laserTypeLe = laserType['LE'] as String?;

    Map<String, dynamic> reParams = {};
    Map<String, dynamic> leParams = {};
    if (params.containsKey('RE') || params.containsKey('LE')) {
      reParams = Map<String, dynamic>.from(params['RE'] as Map? ?? {});
      leParams = Map<String, dynamic>.from(params['LE'] as Map? ?? {});
    } else {
      reParams = params;
      leParams = params;
    }

    _powerReController.text = (reParams['power_mw'] ?? reParams['power'] ?? '')
        .toString();
    _durationReController.text =
        (reParams['duration_ms'] ?? reParams['duration'] ?? '').toString();
    _intervalReController.text = (reParams['interval'] ?? '').toString();
    _spotSizeReController.text =
        (reParams['spot_size_um'] ?? reParams['spot_size'] ?? '').toString();
    _patternRe = reParams['pattern'] as String?;
    _spotSpacingReController.text =
        (reParams['spot_spacing'] ?? '').toString();
    _burnIntensityRe = reParams['burn_intensity'] as String?;

    _powerLeController.text = (leParams['power_mw'] ?? leParams['power'] ?? '')
        .toString();
    _durationLeController.text =
        (leParams['duration_ms'] ?? leParams['duration'] ?? '').toString();
    _intervalLeController.text = (leParams['interval'] ?? '').toString();
    _spotSizeLeController.text =
        (leParams['spot_size_um'] ?? leParams['spot_size'] ?? '').toString();
    _patternLe = leParams['pattern'] as String?;
    _spotSpacingLeController.text =
        (leParams['spot_spacing'] ?? '').toString();
    _burnIntensityLe = leParams['burn_intensity'] as String?;

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
                    child: _buildBcvaDropdown(
                      controller: _bcvaReController,
                      label: 'RE',
                      validator: _required,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBcvaDropdown(
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
              _buildLaserParametersSection(),
              const SizedBox(height: 16),
              const Text(
                'Laser images',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (widget.caseId == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Save the entry first to upload images.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              _buildLaserImagesSection(),
              const SizedBox(height: 16),
              const Text(
                'Laser videos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (widget.caseId == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Save the entry first to upload videos.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              _buildLaserVideosSection(),
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

  Widget _buildBcvaDropdown({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    final normalized = _normalizeBcva(controller.text);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: normalized.isEmpty ? null : normalized,
        items: bcvaOptions
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        decoration: InputDecoration(labelText: label),
        isExpanded: true,
        validator: (val) => validator?.call(val),
        onChanged: (val) {
          setState(() {
            controller.text = val ?? '';
          });
        },
      ),
    );
  }

  String _normalizeBcva(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return '';
    value = value.replaceAll('\\', '/');
    final lower = value.toLowerCase();
    for (final option in bcvaOptions) {
      if (option.toLowerCase() == lower) {
        return option;
      }
    }
    final digitsOnly = RegExp(r'^\d+$');
    if (digitsOnly.hasMatch(value)) {
      final candidate = '6/$value';
      for (final option in bcvaOptions) {
        if (option.toLowerCase() == candidate.toLowerCase()) {
          return option;
        }
      }
    }
    return '';
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
        isExpanded: true,
        selectedItemBuilder: (context) => items
            .map((item) => Text(item, overflow: TextOverflow.ellipsis))
            .toList(),
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ),
            )
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        readOnly: true,
        controller: _examDateController,
        decoration: const InputDecoration(
          labelText: 'Date of examination',
          hintText: 'Select date',
        ),
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
            setState(() {
              _examDate = picked;
              _examDateController.text = _formatDate(picked);
            });
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

  bool _isLaserActive(String? type) {
    if (type == null) return false;
    final value = type.trim().toLowerCase();
    return value.isNotEmpty && value != 'nil';
  }

  Widget _buildLaserParametersSection() {
    final showRe = _isLaserActive(_laserTypeRe);
    final showLe = _isLaserActive(_laserTypeLe);
    if (!showRe && !showLe) {
      return const SizedBox.shrink();
    }

    if (showRe && showLe) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildLaserParamColumn('RE')),
          const SizedBox(width: 12),
          Expanded(child: _buildLaserParamColumn('LE')),
        ],
      );
    }

    return _buildLaserParamColumn(showRe ? 'RE' : 'LE');
  }

  Widget _buildLaserParamColumn(String eye) {
    final isRe = eye == 'RE';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eye,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildText(
          controller: isRe ? _powerReController : _powerLeController,
          label: 'Power (mW)',
          keyboardType: TextInputType.number,
        ),
        _buildText(
          controller: isRe ? _durationReController : _durationLeController,
          label: 'Duration (ms)',
          keyboardType: TextInputType.number,
        ),
        _buildText(
          controller: isRe ? _intervalReController : _intervalLeController,
          label: 'Interval',
        ),
        _buildText(
          controller: isRe ? _spotSizeReController : _spotSizeLeController,
          label: 'Spot size (um)',
          keyboardType: TextInputType.number,
        ),
        _buildDropdown(
          label: 'Pattern',
          value: isRe ? _patternRe : _patternLe,
          items: _patterns,
          onChanged: (v) => setState(() {
            if (isRe) {
              _patternRe = v;
            } else {
              _patternLe = v;
            }
          }),
        ),
        _buildText(
          controller:
              isRe ? _spotSpacingReController : _spotSpacingLeController,
          label: 'Spot spacing',
          keyboardType: TextInputType.number,
        ),
        _buildDropdown(
          label: 'Burn intensity',
          value: isRe ? _burnIntensityRe : _burnIntensityLe,
          items: _burnIntensities,
          onChanged: (v) => setState(() {
            if (isRe) {
              _burnIntensityRe = v;
            } else {
              _burnIntensityLe = v;
            }
          }),
        ),
      ],
    );
  }

  Widget _buildLaserImagesSection() {
    final showRe = _isLaserActive(_laserTypeRe);
    final showLe = _isLaserActive(_laserTypeLe);
    if (!showRe && !showLe) {
      return const SizedBox.shrink();
    }

    if (showRe && showLe) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildLaserImageColumn('RE')),
          const SizedBox(width: 12),
          Expanded(child: _buildLaserImageColumn('LE')),
        ],
      );
    }

    return _buildLaserImageColumn(showRe ? 'RE' : 'LE');
  }

  Widget _buildLaserVideosSection() {
    final showRe = _isLaserActive(_laserTypeRe);
    final showLe = _isLaserActive(_laserTypeLe);
    if (!showRe && !showLe) {
      return const SizedBox.shrink();
    }

    if (showRe && showLe) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildLaserVideoColumn('RE')),
          const SizedBox(width: 12),
          Expanded(child: _buildLaserVideoColumn('LE')),
        ],
      );
    }

    return _buildLaserVideoColumn(showRe ? 'RE' : 'LE');
  }

  Widget _buildLaserImageColumn(String eye) {
    final isRe = eye == 'RE';
    final uploading = isRe ? _uploadingRe : _uploadingLe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eye,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: uploading ? null : () => _pickLaserImage(eye),
          icon: uploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.image_outlined),
          label: Text(uploading ? 'Uploading...' : 'Upload image'),
        ),
      ],
    );
  }

  Widget _buildLaserVideoColumn(String eye) {
    final isRe = eye == 'RE';
    final uploading = isRe ? _uploadingVideoRe : _uploadingVideoLe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eye,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: uploading ? null : () => _pickLaserVideo(eye),
          icon: uploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.videocam_outlined),
          label: Text(uploading ? 'Uploading...' : 'Upload video'),
        ),
      ],
    );
  }

  Future<void> _pickLaserImage(String eye) async {
    if (widget.caseId == null) {
      _showError('Save the entry first to upload images.');
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final ext = p.extension(file.path).toLowerCase();
    const allowedImages = ['.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif'];
    if (!allowedImages.contains(ext)) {
      _showError('Only JPG, PNG, WEBP, or HEIC images are allowed.');
      return;
    }

    setState(() {
      if (eye == 'RE') {
        _uploadingRe = true;
      } else {
        _uploadingLe = true;
      }
    });

    try {
      await ref.read(clinicalCasesRepositoryProvider).uploadMedia(
            caseId: widget.caseId!,
            category: _laserMediaCategory,
            mediaType: 'image',
            file: File(file.path),
            note: 'Laser $eye',
          );
      ref.invalidate(caseMediaProvider(widget.caseId!));
      if (mounted) {
        _showSuccess('Image uploaded for $eye.');
      }
    } catch (e) {
      _showError('Upload failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          if (eye == 'RE') {
            _uploadingRe = false;
          } else {
            _uploadingLe = false;
          }
        });
      }
    }
  }

  Future<void> _pickLaserVideo(String eye) async {
    if (widget.caseId == null) {
      _showError('Save the entry first to upload videos.');
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    final ext = p.extension(file.path).toLowerCase();
    const allowedVideos = ['.mp4', '.mov', '.m4v', '.avi', '.mkv', '.webm', '.3gp'];
    if (!allowedVideos.contains(ext)) {
      _showError('Only MP4, MOV, M4V, AVI, MKV, WEBM, or 3GP videos are allowed.');
      return;
    }

    setState(() {
      if (eye == 'RE') {
        _uploadingVideoRe = true;
      } else {
        _uploadingVideoLe = true;
      }
    });

    try {
      await ref.read(clinicalCasesRepositoryProvider).uploadMedia(
            caseId: widget.caseId!,
            category: _laserMediaCategory,
            mediaType: 'video',
            file: File(file.path),
            note: 'Laser $eye',
          );
      ref.invalidate(caseMediaProvider(widget.caseId!));
      if (mounted) {
        _showSuccess('Video uploaded for $eye.');
      }
    } catch (e) {
      _showError('Upload failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          if (eye == 'RE') {
            _uploadingVideoRe = false;
          } else {
            _uploadingVideoLe = false;
          }
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccess(String message) {
    final caseId = widget.caseId;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
        action: caseId == null
            ? null
            : SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () => context.push('/cases/$caseId/media'),
              ),
      ),
    );
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
          context.go('/cases/laser/$id');
        }
      } else {
        await mutation.update(widget.caseId!, data);
        if (mounted) {
          context.go('/cases/laser/${widget.caseId}');
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
    final params = <String, dynamic>{};
    if (_isLaserActive(_laserTypeRe)) {
      params['RE'] = {
        'power_mw': _powerReController.text.trim(),
        'duration_ms': _durationReController.text.trim(),
        'interval': _intervalReController.text.trim(),
        'spot_size_um': _spotSizeReController.text.trim(),
        'pattern': _patternRe,
        'spot_spacing': _spotSpacingReController.text.trim(),
        'burn_intensity': _burnIntensityRe,
      };
    }
    if (_isLaserActive(_laserTypeLe)) {
      params['LE'] = {
        'power_mw': _powerLeController.text.trim(),
        'duration_ms': _durationLeController.text.trim(),
        'interval': _intervalLeController.text.trim(),
        'spot_size_um': _spotSizeLeController.text.trim(),
        'pattern': _patternLe,
        'spot_spacing': _spotSpacingLeController.text.trim(),
        'burn_intensity': _burnIntensityLe,
      };
    }
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
        'parameters': params,
      },
    };
  }
}
