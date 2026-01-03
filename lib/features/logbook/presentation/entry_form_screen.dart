import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../application/logbook_providers.dart';
import '../data/media_repository.dart';
import '../domain/elog_entry.dart';
import '../domain/surgical_learning_options.dart';
import '../domain/atlas_media_types.dart';
import '../../quality/data/quality_repository.dart';
import '../../taxonomy/data/taxonomy_repository.dart';

class EntryFormScreen extends ConsumerStatefulWidget {
  const EntryFormScreen({super.key, this.entryId, this.moduleType});

  final String? entryId;
  final String? moduleType;

  @override
  ConsumerState<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends ConsumerState<EntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientController = TextEditingController();
  final _mrnController = TextEditingController();
  final _keywordsController = TextEditingController();
  // Module-specific controllers
  final _briefDescController = TextEditingController();
  final _followUpDescController = TextEditingController();

  final _keyDescriptionController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  final _atlasDiagnosisController = TextEditingController();
  final _atlasBriefController = TextEditingController();
  final _recordPatientNameController = TextEditingController();
  final _recordAgeController = TextEditingController();
  final _recordDiagnosisController = TextEditingController();
  final _recordAssistedByController = TextEditingController();
  final _recordDurationController = TextEditingController();
  final _recordSurgicalNotesController = TextEditingController();
  final _recordComplicationsController = TextEditingController();

  final _preOpController = TextEditingController();
  final _surgicalVideoController = TextEditingController();
  final _teachingPointController = TextEditingController();
  final _surgeonController = TextEditingController();
  final _learningPointController = TextEditingController();
  final _surgeonAssistantController = TextEditingController();

  String? _moduleType;
  String _currentStatus = statusDraft;
  List<String> _existingImagePaths = [];
  List<String> _existingVideoPaths = [];
  List<String> _existingRecordPreOpImagePaths = [];
  List<String> _existingRecordPostOpImagePaths = [];
  final List<File> _newImages = [];
  final List<File> _newVideos = [];
  final List<File> _newRecordPreOpImages = [];
  final List<File> _newRecordPostOpImages = [];
  String? _mediaType;
  String? _recordSex;
  String? _recordSurgery;
  String? _learningSurgery;
  String? _recordRightEye;
  String? _recordLeftEye;

  @override
  void initState() {
    super.initState();
    _moduleType = widget.moduleType ?? moduleCases;
    if (widget.entryId != null) {
      _loadEntry();
    }
  }

  bool get _canEditStatus =>
      _currentStatus == statusDraft || _currentStatus == statusNeedsRevision;

  Future<void> _loadEntry() async {
    final entry = await ref.read(entryDetailProvider(widget.entryId!).future);
    setState(() {
      _moduleType = entry.moduleType;
      _currentStatus = entry.status;
      _patientController.text = entry.patientUniqueId;
      _mrnController.text = entry.mrn;
      _keywordsController.text = entry.keywords.join(', ');
      final payload = entry.payload;
      switch (entry.moduleType) {
        case moduleCases:
          _briefDescController.text = payload['briefDescription'] ?? '';
          _followUpDescController.text =
              payload['followUpVisitDescription'] ?? '';
          _existingImagePaths = [
            ...List<String>.from(payload['ancillaryImagingPaths'] ?? []),
            ...List<String>.from(payload['followUpVisitImagingPaths'] ?? []),
          ];
          break;
        case moduleImages:
          _mediaType = payload['mediaType'] as String?;
          _atlasDiagnosisController.text =
              payload['diagnosis'] ??
              payload['keyDescriptionOrPathology'] ??
              '';
          _atlasBriefController.text =
              payload['briefDescription'] ??
              payload['additionalInformation'] ??
              '';
          _keyDescriptionController.text = _atlasDiagnosisController.text;
          _additionalInfoController.text = _atlasBriefController.text;
          _existingImagePaths = [
            ...List<String>.from(payload['uploadImagePaths'] ?? []),
            ...List<String>.from(payload['followUpVisitImagingPaths'] ?? []),
          ];
          break;
        case moduleLearning:
          _learningSurgery =
              payload['surgery'] ?? payload['preOpDiagnosisOrPathology'];
          _teachingPointController.text =
              payload['stepName'] ?? payload['teachingPoint'] ?? '';
          _surgeonController.text =
              payload['consultantName'] ?? payload['surgeon'] ?? '';
          _existingVideoPaths = List<String>.from(payload['videoPaths'] ?? []);
          break;
        case moduleRecords:
          _recordPatientNameController.text = payload['patientName'] ?? '';
          _recordAgeController.text = payload['age']?.toString() ?? '';
          final sex = payload['sex'] as String? ?? '';
          _recordSex = sex.isEmpty
              ? null
              : '${sex[0].toUpperCase()}${sex.substring(1).toLowerCase()}';
          _recordDiagnosisController.text =
              payload['diagnosis'] ??
              payload['preOpDiagnosisOrPathology'] ??
              '';
          _recordSurgery =
              payload['surgery'] ?? payload['learningPointOrComplication'];
          _recordAssistedByController.text =
              payload['assistedBy'] ?? payload['surgeonOrAssistant'] ?? '';
          _recordDurationController.text = payload['duration'] ?? '';
          _recordRightEye = payload['rightEye'] as String?;
          _recordLeftEye = payload['leftEye'] as String?;
          _recordSurgicalNotesController.text = payload['surgicalNotes'] ?? '';
          _recordComplicationsController.text = payload['complications'] ?? '';
          _existingVideoPaths = List<String>.from(payload['videoPaths'] ?? []);
          _existingRecordPreOpImagePaths = List<String>.from(
            payload['preOpImagePaths'] ?? [],
          );
          _existingRecordPostOpImagePaths = List<String>.from(
            payload['postOpImagePaths'] ?? [],
          );
          break;
      }
    });
  }

  @override
  void dispose() {
    _patientController.dispose();
    _mrnController.dispose();
    _keywordsController.dispose();
    _briefDescController.dispose();
    _followUpDescController.dispose();
    _keyDescriptionController.dispose();
    _additionalInfoController.dispose();
    _atlasDiagnosisController.dispose();
    _atlasBriefController.dispose();
    _recordPatientNameController.dispose();
    _recordAgeController.dispose();
    _recordDiagnosisController.dispose();
    _recordAssistedByController.dispose();
    _recordDurationController.dispose();
    _recordSurgicalNotesController.dispose();
    _recordComplicationsController.dispose();
    _preOpController.dispose();
    _surgicalVideoController.dispose();
    _teachingPointController.dispose();
    _surgeonController.dispose();
    _learningPointController.dispose();
    _surgeonAssistantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entryId != null;
    final isAtlas = _moduleType == moduleImages;
    final isRecords = _moduleType == moduleRecords;
    final isLearning = _moduleType == moduleLearning;
    final mutation = ref.watch(entryMutationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Entry' : 'Clinical Case Wizard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      backgroundColor: const Color(0xFFF7F9FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 22,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress and section header
                      Text(
                        'Step 1 of 8',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Patient Details',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: 1 / 8,
                        minHeight: 5,
                        backgroundColor: Colors.blue[100],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue[400]!,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 18),
                      // Main form fields (add more as needed)
                      // Example: Patient name
                      _buildText(
                        controller: _patientController,
                        label: 'Patient Unique ID',
                        validator: _required,
                        enabled: _canEditStatus,
                      ),
                      _buildText(
                        controller: _mrnController,
                        label: 'MRN',
                        validator: _required,
                        enabled: _canEditStatus,
                      ),
                      // Add more fields and sections as needed for your form
                      // ...existing code...
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  Widget _buildText({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF3F6FA),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFBFD7ED)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFBFD7ED)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF0B5FFF), width: 2),
          ),
        ),
        validator: validator,
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildSexDropdown() {
    const options = ['Male', 'Female'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: _recordSex,
        decoration: const InputDecoration(labelText: 'Sex'),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        onChanged: _canEditStatus
            ? (value) => setState(() => _recordSex = value)
            : null,
      ),
    );
  }

  Widget _buildSurgeryDropdown() {
    final options = List<String>.from(_surgeryOptions);
    final current = _recordSurgery;
    if (current != null && current.isNotEmpty && !options.contains(current)) {
      options.insert(0, current);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: current == null || current.isEmpty ? null : current,
        decoration: const InputDecoration(labelText: 'Surgery'),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        onChanged: _canEditStatus
            ? (value) => setState(() => _recordSurgery = value)
            : null,
      ),
    );
  }

  Widget _buildEyeDropdownRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildEyeDropdown(
              label: 'Right eye',
              value: _recordRightEye,
              onChanged: _canEditStatus
                  ? (value) => setState(() => _recordRightEye = value)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildEyeDropdown(
              label: 'Left eye',
              value: _recordLeftEye,
              onChanged: _canEditStatus
                  ? (value) => setState(() => _recordLeftEye = value)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEyeDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?>? onChanged,
  }) {
    const options = ['Operated', 'Not operated'];
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      onChanged: onChanged,
    );
  }

  Widget _buildLearningSurgeryDropdown() {
    final options = List<String>.from(_surgeryOptions);
    final current = _learningSurgery;
    if (current != null && current.isNotEmpty && !options.contains(current)) {
      options.insert(0, current);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: current == null || current.isEmpty ? null : current,
        decoration: const InputDecoration(labelText: 'Name of the surgery'),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        onChanged: _canEditStatus
            ? (value) => setState(() => _learningSurgery = value)
            : null,
      ),
    );
  }

  Widget _buildLearningStepDropdown() {
    final current = _teachingPointController.text.trim();
    final options = [...surgicalLearningOptions];
    if (current.isNotEmpty && !options.contains(current)) {
      options.insert(0, current);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: current.isEmpty ? null : current,
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        decoration: const InputDecoration(labelText: 'Name of the step'),
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        onChanged: _canEditStatus
            ? (v) => _teachingPointController.text = v ?? ''
            : null,
      ),
    );
  }

  List<String> get _surgeryOptions => const [
    'SOR',
    'VH',
    'RRD',
    'SFIOL',
    'MH',
    'Scleral buckle',
    'Belt buckle',
    'ERM',
    'TRD',
    'PPL+PPV+SFIOL',
    'ROP laser',
  ];

  Future<void> _save({required bool submit}) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canEditStatus) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot edit this status')),
        );
      }
      return;
    }
    final module = _moduleType ?? moduleCases;
    final keywords = module == moduleRecords
        ? _buildRecordKeywords()
        : module == moduleLearning
        ? _buildLearningKeywords()
        : _keywordsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

    final mediaRepo = ref.read(mediaRepositoryProvider);
    Map<String, dynamic> payload = _buildPayload(module);

    try {
      if (widget.entryId == null) {
        final patientId = module == moduleLearning
            ? (_learningSurgery?.trim() ?? '')
            : _patientController.text.trim();
        final mrn = module == moduleLearning
            ? _teachingPointController.text.trim()
            : _mrnController.text.trim();
        final create = ElogEntryCreate(
          moduleType: module,
          patientUniqueId: patientId,
          mrn: mrn,
          keywords: keywords,
          payload: payload,
        );
        await ref.read(entryMutationProvider.notifier).create(create);
      } else {
        final entryId = widget.entryId!;
        final newPaths = await _uploadNewImages(mediaRepo, entryId, _newImages);
        if (newPaths.isNotEmpty) {
          payload = _withNewPaths(module, payload, newPaths);
        }
        if (module == moduleRecords) {
          final prePaths = await _uploadNewImages(
            mediaRepo,
            entryId,
            _newRecordPreOpImages,
          );
          final postPaths = await _uploadNewImages(
            mediaRepo,
            entryId,
            _newRecordPostOpImages,
          );
          if (prePaths.isNotEmpty || postPaths.isNotEmpty) {
            payload = _withRecordImagePaths(payload, prePaths, postPaths);
          }
        }
        if (module == moduleRecords || module == moduleLearning) {
          final videoPaths = await _uploadNewVideos(mediaRepo, entryId);
          if (videoPaths.isNotEmpty) {
            payload = _withNewVideos(payload, videoPaths);
          }
        }
        final patientId = module == moduleLearning
            ? (_learningSurgery?.trim() ?? '')
            : _patientController.text.trim();
        final mrn = module == moduleLearning
            ? _teachingPointController.text.trim()
            : _mrnController.text.trim();
        final update = ElogEntryUpdate(
          patientUniqueId: patientId,
          mrn: mrn,
          keywords: keywords,
          payload: payload,
          status: submit ? statusSubmitted : _currentStatus,
          submittedAt: submit ? DateTime.now() : null,
          clearReview: submit,
        );
        await ref.read(entryMutationProvider.notifier).update(entryId, update);
      }
      // Re-score quality after save/update
      try {
        await ref
            .read(qualityRepositoryProvider)
            .scoreEntry(widget.entryId ?? '');
      } catch (_) {}
      if (mounted) {
        context.go('/logbook');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  Future<List<String>> _uploadNewImages(
    MediaRepository mediaRepo,
    String entryId,
    List<File> images,
  ) async {
    final newPaths = <String>[];
    for (final file in images) {
      final path = await mediaRepo.uploadImage(entryId: entryId, file: file);
      newPaths.add(path);
    }
    return newPaths;
  }

  Future<List<String>> _uploadNewVideos(
    MediaRepository mediaRepo,
    String entryId,
  ) async {
    final newPaths = <String>[];
    for (final file in _newVideos) {
      final path = await mediaRepo.uploadImage(entryId: entryId, file: file);
      newPaths.add(path);
    }
    return newPaths;
  }

  Map<String, dynamic> _buildPayload(String module) {
    switch (module) {
      case moduleCases:
        return {
          'briefDescription': _briefDescController.text.trim(),
          'followUpVisitDescription': _followUpDescController.text.trim(),
          'ancillaryImagingPaths': _existingImagePaths,
          'followUpVisitImagingPaths': <String>[],
        };
      case moduleImages:
        final uploadPaths = _existingImagePaths;
        return {
          'uploadImagePaths': uploadPaths,
          'mediaType': _mediaType,
          'diagnosis': _atlasDiagnosisController.text.trim(),
          'briefDescription': _atlasBriefController.text.trim(),
          'keyDescriptionOrPathology': _atlasDiagnosisController.text.trim(),
          'additionalInformation': _atlasBriefController.text.trim(),
          'followUpVisitImagingPaths': <String>[],
        };
      case moduleLearning:
        final surgery = _learningSurgery?.trim() ?? '';
        final step = _teachingPointController.text.trim();
        final consultant = _surgeonController.text.trim();
        return {
          'surgery': surgery,
          'stepName': step,
          'consultantName': consultant,
          'videoPaths': _existingVideoPaths,
          'preOpDiagnosisOrPathology': surgery,
          'teachingPoint': step,
          'surgeon': consultant,
          'surgicalVideoLink': '',
        };
      case moduleRecords:
        final ageText = _recordAgeController.text.trim();
        final age = int.tryParse(ageText);
        final diagnosis = _recordDiagnosisController.text.trim();
        final assistedBy = _recordAssistedByController.text.trim();
        final surgery = _recordSurgery?.trim() ?? '';
        return {
          'patientName': _recordPatientNameController.text.trim(),
          'age': age ?? ageText,
          'sex': _recordSex,
          'diagnosis': diagnosis,
          'surgery': surgery,
          'assistedBy': assistedBy,
          'duration': _recordDurationController.text.trim(),
          'rightEye': _recordRightEye,
          'leftEye': _recordLeftEye,
          'surgicalNotes': _recordSurgicalNotesController.text.trim(),
          'complications': _recordComplicationsController.text.trim(),
          'preOpImagePaths': _existingRecordPreOpImagePaths,
          'postOpImagePaths': _existingRecordPostOpImagePaths,
          'videoPaths': _existingVideoPaths,
          'preOpDiagnosisOrPathology': diagnosis,
          'learningPointOrComplication': surgery,
          'surgeonOrAssistant': assistedBy,
        };
      default:
        return {};
    }
  }

  Map<String, dynamic> _withNewPaths(
    String module,
    Map<String, dynamic> payload,
    List<String> newPaths,
  ) {
    final updated = Map<String, dynamic>.from(payload);
    switch (module) {
      case moduleCases:
        final existing = List<String>.from(
          updated['ancillaryImagingPaths'] ?? [],
        );
        updated['ancillaryImagingPaths'] = [...existing, ...newPaths];
        break;
      case moduleImages:
        final existing = List<String>.from(updated['uploadImagePaths'] ?? []);
        updated['uploadImagePaths'] = [...existing, ...newPaths];
        break;
    }
    return updated;
  }

  Map<String, dynamic> _withNewVideos(
    Map<String, dynamic> payload,
    List<String> newPaths,
  ) {
    final updated = Map<String, dynamic>.from(payload);
    final existing = List<String>.from(updated['videoPaths'] ?? []);
    updated['videoPaths'] = [...existing, ...newPaths];
    return updated;
  }

  Map<String, dynamic> _withRecordImagePaths(
    Map<String, dynamic> payload,
    List<String> preOpPaths,
    List<String> postOpPaths,
  ) {
    final updated = Map<String, dynamic>.from(payload);
    final existingPre = List<String>.from(updated['preOpImagePaths'] ?? []);
    final existingPost = List<String>.from(updated['postOpImagePaths'] ?? []);
    updated['preOpImagePaths'] = [...existingPre, ...preOpPaths];
    updated['postOpImagePaths'] = [...existingPost, ...postOpPaths];
    return updated;
  }

  List<String> _buildRecordKeywords() {
    final seeds = [
      _recordDiagnosisController.text.trim(),
      _recordSurgery?.trim() ?? '',
    ];
    final keywords = <String>[];
    for (final seed in seeds) {
      if (seed.isEmpty) continue;
      final parts = seed
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty);
      for (final part in parts) {
        if (keywords.every((k) => k.toLowerCase() != part.toLowerCase())) {
          keywords.add(part);
        }
      }
    }
    if (keywords.isEmpty) {
      keywords.add('record');
    }
    return keywords;
  }

  List<String> _buildLearningKeywords() {
    final seeds = [
      _learningSurgery?.trim() ?? '',
      _teachingPointController.text.trim(),
    ];
    final keywords = <String>[];
    for (final seed in seeds) {
      if (seed.isEmpty) continue;
      final parts = seed
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty);
      for (final part in parts) {
        if (keywords.every((k) => k.toLowerCase() != part.toLowerCase())) {
          keywords.add(part);
        }
      }
    }
    if (keywords.isEmpty) {
      keywords.add('learning');
    }
    return keywords;
  }
}

class _ModuleFields extends StatelessWidget {
  const _ModuleFields({
    required this.moduleType,
    required this.briefDescController,
    required this.followUpDescController,
    required this.keyDescriptionController,
    required this.additionalInfoController,
    required this.atlasDiagnosisController,
    required this.atlasBriefController,
    required this.mediaType,
    required this.onMediaTypeChanged,
    required this.preOpController,
    required this.surgicalVideoController,
    required this.teachingPointController,
    required this.surgeonController,
    required this.learningPointController,
    required this.surgeonAssistantController,
    required this.enabled,
  });

  final String moduleType;
  final TextEditingController briefDescController;
  final TextEditingController followUpDescController;
  final TextEditingController keyDescriptionController;
  final TextEditingController additionalInfoController;
  final TextEditingController atlasDiagnosisController;
  final TextEditingController atlasBriefController;
  final String? mediaType;
  final ValueChanged<String?> onMediaTypeChanged;
  final TextEditingController preOpController;
  final TextEditingController surgicalVideoController;
  final TextEditingController teachingPointController;
  final TextEditingController surgeonController;
  final TextEditingController learningPointController;
  final TextEditingController surgeonAssistantController;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    switch (moduleType) {
      case moduleCases:
        return Column(
          children: [
            _buildField(
              controller: briefDescController,
              label: 'Brief Description',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
              enabled: enabled,
            ),
            _buildField(
              controller: followUpDescController,
              label: 'Follow-up Visit Description (optional)',
              enabled: enabled,
            ),
          ],
        );
      case moduleImages:
        return Column(
          children: [
            _buildMediaTypeDropdown(
              value: mediaType,
              onChanged: enabled ? onMediaTypeChanged : null,
            ),
            _buildField(
              controller: atlasDiagnosisController,
              label: 'Diagnosis',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
              enabled: enabled,
            ),
            _buildField(
              controller: atlasBriefController,
              label: 'Brief description',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
              enabled: enabled,
            ),
          ],
        );
      case moduleLearning:
        return Column(
          children: [
            _buildField(
              controller: preOpController,
              label: 'Pre-op diagnosis / pathology',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
              enabled: enabled,
            ),
            _buildField(
              controller: surgicalVideoController,
              label: 'Surgical video link (URL)',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
              enabled: enabled,
            ),
            _buildSurgicalLearningDropdown(
              controller: teachingPointController,
              enabled: enabled,
            ),
            _buildField(
              controller: surgeonController,
              label: 'Surgeon',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
              enabled: enabled,
            ),
          ],
        );
      case moduleRecords:
        return Column(
          children: [
            _buildField(
              controller: preOpController,
              label: 'Pre-op diagnosis / pathology',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
              enabled: enabled,
            ),
            _buildField(
              controller: surgicalVideoController,
              label: 'Surgical video link (URL)',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
              enabled: enabled,
            ),
            _buildField(
              controller: learningPointController,
              label: 'Learning point or complication',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
              enabled: enabled,
            ),
            _buildField(
              controller: surgeonAssistantController,
              label: 'Surgeon or assistant',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
              enabled: enabled,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(labelText: label),
        validator: validator,
      ),
    );
  }

  Widget _buildSurgicalLearningDropdown({
    required TextEditingController controller,
    required bool enabled,
  }) {
    final current = controller.text.trim();
    final options = [...surgicalLearningOptions];
    if (current.isNotEmpty && !options.contains(current)) {
      options.insert(0, current);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: current.isEmpty ? null : current,
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        decoration: const InputDecoration(labelText: 'Teaching point'),
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        onChanged: enabled ? (v) => controller.text = v ?? '' : null,
      ),
    );
  }

  Widget _buildMediaTypeDropdown({
    required String? value,
    required ValueChanged<String?>? onChanged,
  }) {
    final options = [...atlasMediaTypes];
    if (value != null && value.isNotEmpty && !options.contains(value)) {
      options.insert(0, value);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value == null || value.isEmpty ? null : value,
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        decoration: const InputDecoration(labelText: 'Type of media'),
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        onChanged: onChanged,
      ),
    );
  }
}

class _ImagePickerSection extends ConsumerWidget {
  const _ImagePickerSection({
    this.title = 'Images',
    required this.existingPaths,
    required this.newImages,
    required this.onChanged,
    required this.enabled,
  });

  final String title;
  final List<String> existingPaths;
  final List<File> newImages;
  final VoidCallback onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedCache = ref.watch(signedUrlCacheProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: !enabled
                  ? null
                  : () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickMultiImage();
                      if (picked.isNotEmpty) {
                        newImages.addAll(picked.map((e) => File(e.path)));
                        onChanged();
                      }
                    },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...existingPaths.map(
              (path) => FutureBuilder(
                future: signedCache.getUrl(path),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 80,
                      width: 80,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      snapshot.data!,
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
            ...newImages.map(
              (file) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  file,
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VideoPickerSection extends ConsumerWidget {
  const _VideoPickerSection({
    required this.existingPaths,
    required this.newVideos,
    required this.onChanged,
    required this.enabled,
  });

  final List<String> existingPaths;
  final List<File> newVideos;
  final VoidCallback onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedCache = ref.watch(signedUrlCacheProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Videos', style: TextStyle(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: !enabled
                  ? null
                  : () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickVideo(
                        source: ImageSource.gallery,
                      );
                      if (picked != null) {
                        newVideos.add(File(picked.path));
                        onChanged();
                      }
                    },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            ...existingPaths.map(
              (path) => FutureBuilder(
                future: signedCache.getUrl(path),
                builder: (context, snapshot) {
                  final fileName = path.split('/').last;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.videocam_outlined),
                    title: Text(fileName),
                    trailing: TextButton(
                      onPressed: snapshot.hasData
                          ? () => launchUrl(Uri.parse(snapshot.data!))
                          : null,
                      child: const Text('Open'),
                    ),
                  );
                },
              ),
            ),
            ...newVideos.map(
              (file) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.videocam_outlined),
                title: Text(file.path.split('/').last),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: !enabled
                      ? null
                      : () {
                          newVideos.remove(file);
                          onChanged();
                        },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeywordSuggestionsField extends ConsumerStatefulWidget {
  const _KeywordSuggestionsField({required this.controller});
  final TextEditingController controller;

  @override
  ConsumerState<_KeywordSuggestionsField> createState() =>
      _KeywordSuggestionsFieldState();
}

class _KeywordSuggestionsFieldState
    extends ConsumerState<_KeywordSuggestionsField> {
  String current = '';
  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(taxonomyRepositoryProvider);
    final last = current.split(',').last.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        if (last.length >= 2)
          FutureBuilder(
            future: repo.autocomplete(last),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final terms = snapshot.data!;
              if (terms.isEmpty) {
                return TextButton(
                  onPressed: () async {
                    await repo.suggest(last);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Suggested new term')),
                    );
                  },
                  child: Text('Suggest "$last"'),
                );
              }
              return Wrap(
                spacing: 6,
                children: terms
                    .map(
                      (t) => ActionChip(
                        label: Text(t.term),
                        onPressed: () {
                          final existing = widget.controller.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          existing.removeWhere(
                            (e) => e.toLowerCase() == last.toLowerCase(),
                          );
                          existing.add(t.term);
                          widget.controller.text = existing.join(', ');
                          setState(() => current = widget.controller.text);
                        },
                      ),
                    )
                    .toList(),
              );
            },
          ),
        TextField(
          controller: widget.controller,
          decoration: const InputDecoration(
            hintText: 'Type keywords (comma separated)',
          ),
          onChanged: (v) => setState(() => current = v),
        ),
      ],
    );
  }
}
