import 'dart:io';

import 'package:file_picker/file_picker.dart';
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
          _existingVideoPaths = List<String>.from(payload['videoPaths'] ?? []);
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
        title: Text(isEditing 
            ? 'Edit Entry' 
            : isAtlas 
                ? 'New Atlas Entry'
                : isRecords
                    ? 'New Surgical Record'
                    : isLearning
                        ? 'New Learning Entry'
                        : 'Clinical Case Wizard'),
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
                      if (!isAtlas && !isRecords && !isLearning) ...[
                        // Progress and section header for Clinical Cases only
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
                      ],
                      // Single unified card for all form sections
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Patient Information section (for Atlas and Surgical Records)
                              if (!isLearning && (isAtlas || isRecords)) ...[
                                _buildSectionHeader('Patient Information', Icons.person_outline_rounded),
                                const SizedBox(height: 16),
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
                                const Divider(height: 32),
                              ],
                              
                              // Atlas specific sections
                              if (isAtlas) ...[
                                _buildSectionHeader('Atlas Details', Icons.image_outlined),
                                const SizedBox(height: 16),
                                _ModuleFields(
                                  moduleType: _moduleType!,
                                  briefDescController: _briefDescController,
                                  followUpDescController: _followUpDescController,
                                  keyDescriptionController: _keyDescriptionController,
                                  additionalInfoController: _additionalInfoController,
                                  atlasDiagnosisController: _atlasDiagnosisController,
                                  atlasBriefController: _atlasBriefController,
                                  mediaType: _mediaType,
                                  onMediaTypeChanged: (value) =>
                                      setState(() => _mediaType = value),
                                  preOpController: _preOpController,
                                  surgicalVideoController: _surgicalVideoController,
                                  teachingPointController: _teachingPointController,
                                  surgeonController: _surgeonController,
                                  learningPointController: _learningPointController,
                                  surgeonAssistantController: _surgeonAssistantController,
                                  enabled: _canEditStatus,
                                ),
                                const Divider(height: 32),
                                _buildSectionHeader('Keywords', Icons.label_outline_rounded),
                                const SizedBox(height: 16),
                                _buildText(
                                  controller: _keywordsController,
                                  label: 'Keywords (comma separated)',
                                  validator: _required,
                                  enabled: _canEditStatus,
                                ),
                                if (_canEditStatus)
                                  _KeywordSuggestionsField(
                                    controller: _keywordsController,
                                  ),
                                const Divider(height: 32),
                                _buildSectionHeader('Upload Files', Icons.insert_drive_file_outlined),
                                const SizedBox(height: 16),
                                _FilePickerSection(
                                  title: 'Files',
                                  existingPaths: _existingImagePaths,
                                  newFiles: _newImages,
                                  onChanged: () {
                                    if (!mounted) return;
                                    setState(() {});
                                  },
                                  enabled: _canEditStatus,
                                ),
                                const Divider(height: 32),
                                _buildSectionHeader('Upload Videos', Icons.video_library_outlined),
                                const SizedBox(height: 16),
                                _VideoPickerSection(
                                  existingPaths: _existingVideoPaths,
                                  newVideos: _newVideos,
                                  onChanged: () => setState(() {}),
                                  enabled: _canEditStatus,
                                ),
                              ] else if (isRecords) ...[
                                _buildSectionHeader('Patient Details', Icons.person_outline_rounded),
                                const SizedBox(height: 16),
                                _buildText(
                                  controller: _recordPatientNameController,
                                  label: 'Patient Name',
                                  validator: _required,
                                  enabled: _canEditStatus,
                                ),
                                _buildText(
                                  controller: _recordAgeController,
                                  label: 'Age',
                                  validator: _required,
                                  enabled: _canEditStatus,
                                  keyboardType: TextInputType.number,
                                ),
                                _buildSexDropdown(),
                                const Divider(height: 32),
                                _buildSectionHeader('Surgery Details', Icons.medical_services_outlined),
                                const SizedBox(height: 16),
                                _buildText(
                                  controller: _recordDiagnosisController,
                                  label: 'Diagnosis',
                                  validator: _required,
                                  enabled: _canEditStatus,
                                ),
                                _buildSurgeryDropdown(),
                                _buildText(
                                  controller: _recordAssistedByController,
                                  label: 'Assisted by',
                                  validator: _required,
                                  enabled: _canEditStatus,
                                ),
                                _buildText(
                                  controller: _recordDurationController,
                                  label: 'Duration',
                                  validator: _required,
                                  enabled: _canEditStatus,
                                ),
                                _buildEyeDropdownRow(),
                                _buildText(
                                  controller: _recordSurgicalNotesController,
                                  label: 'Surgical notes',
                                  enabled: _canEditStatus,
                                ),
                                _buildText(
                                  controller: _recordComplicationsController,
                                  label: 'Complications',
                                  enabled: _canEditStatus,
                                ),
                                const Divider(height: 32),
                                _buildSectionHeader('Keywords', Icons.label_outline_rounded),
                                const SizedBox(height: 16),
                                _buildText(
                                  controller: _keywordsController,
                                  label: 'Keywords (comma separated)',
                                  validator: _required,
                                  enabled: _canEditStatus,
                                ),
                                if (_canEditStatus)
                                  _KeywordSuggestionsField(
                                    controller: _keywordsController,
                                  ),
                                const Divider(height: 32),
                                _buildSectionHeader('Surgical Images', Icons.photo_library_outlined),
                                const SizedBox(height: 16),
                                _ImagePickerSection(
                                  title: 'Pre-Op Images',
                                  existingPaths: _existingRecordPreOpImagePaths,
                                  newImages: _newRecordPreOpImages,
                                  onChanged: () => setState(() {}),
                                  enabled: _canEditStatus,
                                ),
                                const SizedBox(height: 16),
                                _ImagePickerSection(
                                  title: 'Post-Op Images',
                                  existingPaths: _existingRecordPostOpImagePaths,
                                  newImages: _newRecordPostOpImages,
                                  onChanged: () => setState(() {}),
                                  enabled: _canEditStatus,
                                ),
                                const Divider(height: 32),
                                _buildSectionHeader('Upload Videos', Icons.video_library_outlined),
                                const SizedBox(height: 16),
                                _VideoPickerSection(
                                  existingPaths: _existingVideoPaths,
                                  newVideos: _newVideos,
                                  onChanged: () => setState(() {}),
                                  enabled: _canEditStatus,
                                ),
                              ] else if (isLearning) ...[
                                _buildSectionHeader('Learning Module Details', Icons.school_outlined),
                                const SizedBox(height: 16),
                                _buildLearningSurgeryDropdown(),
                                _buildLearningStepDropdown(),
                                _buildText(
                                  controller: _surgeonController,
                                  label: 'Consultant name',
                                  validator: _required,
                                  enabled: _canEditStatus,
                                ),
                                const Divider(height: 32),
                                _buildSectionHeader('Keywords', Icons.label_outline_rounded),
                                const SizedBox(height: 16),
                                _buildText(
                                  controller: _keywordsController,
                                  label: 'Keywords (comma separated)',
                                  validator: _required,
                                  enabled: _canEditStatus,
                                ),
                                if (_canEditStatus)
                                  _KeywordSuggestionsField(
                                    controller: _keywordsController,
                                  ),
                                const Divider(height: 32),
                                _buildSectionHeader('Upload Videos', Icons.video_library_outlined),
                                const SizedBox(height: 16),
                                _VideoPickerSection(
                                  existingPaths: _existingVideoPaths,
                                  newVideos: _newVideos,
                                  onChanged: () => setState(() {}),
                                  enabled: _canEditStatus,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: mutation.isLoading || !_canEditStatus
                              ? null
                              : () => _save(submit: false),
                          child: mutation.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save'),
                        ),
                      ),
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    List<Color> gradientColors = const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: gradientColors[0],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF3B82F6),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
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
    const options = ['Operated', 'Not Operated'];
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: options
          .map((o) => DropdownMenuItem(
            value: o,
            child: Text(
              o,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ))
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
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Name of the surgery'),
        items: options
            .map((o) => DropdownMenuItem(
              value: o,
              child: Text(
                o,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ))
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
        isExpanded: true,
        items: options
            .map((o) => DropdownMenuItem(
              value: o,
              child: Text(
                o,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ))
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
        if (module == moduleRecords ||
            module == moduleLearning ||
            module == moduleImages) {
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
      
      // Refresh entries list
      ref.invalidate(entriesListProvider);
      
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
          'videoPaths': _existingVideoPaths,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Type Field
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.category_rounded,
                    color: Color(0xFF3B82F6),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Media Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMediaTypeDropdown(
              value: mediaType,
              onChanged: enabled ? onMediaTypeChanged : null,
            ),
            const SizedBox(height: 20),
            // Diagnosis Field
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.medical_information_rounded,
                    color: Color(0xFF3B82F6),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Diagnosis',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: atlasDiagnosisController,
              label: 'Enter diagnosis',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
              enabled: enabled,
            ),
            const SizedBox(height: 20),
            // Brief Description Field
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.description_rounded,
                    color: Color(0xFF3B82F6),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: atlasBriefController,
              label: 'Enter brief description',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
              enabled: enabled,
              maxLines: 3,
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
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w500,
        ),
      ),
      validator: validator,
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
    return DropdownButtonFormField<String>(
      value: value == null || value.isEmpty ? null : value,
      items: options
          .map((o) => DropdownMenuItem(
                value: o,
                child: Row(
                  children: [
                    Icon(
                      _getMediaIcon(o),
                      size: 18,
                      color: const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(width: 10),
                    Text(o),
                  ],
                ),
              ))
          .toList(),
      decoration: InputDecoration(
        labelText: 'Select media type',
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        prefixIcon: const Icon(
          Icons.category_rounded,
          color: Color(0xFF8B5CF6),
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w500,
        ),
      ),
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'Required' : null,
      onChanged: onChanged,
    );
  }

  IconData _getMediaIcon(String mediaType) {
    if (mediaType.toLowerCase().contains('photo')) return Icons.photo_camera;
    if (mediaType.toLowerCase().contains('video')) return Icons.videocam;
    if (mediaType.toLowerCase().contains('xray')) return Icons.scanner;
    if (mediaType.toLowerCase().contains('scan')) return Icons.medical_information;
    return Icons.image;
  }
}

class _FilePickerSection extends ConsumerWidget {
  const _FilePickerSection({
    this.title = 'Files',
    required this.existingPaths,
    required this.newFiles,
    required this.onChanged,
    required this.enabled,
  });

  final String title;
  final List<String> existingPaths;
  final List<File> newFiles;
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
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton.icon(
              onPressed: !enabled
                  ? null
                  : () async {
                      try {
                        final result = await FilePicker.platform.pickFiles(
                          allowMultiple: true,
                          type: FileType.any,
                        );
                        if (result == null) return;
                        final files = result.files
                            .where((file) => file.path != null)
                            .map((file) => File(file.path!))
                            .toList();
                        if (files.isNotEmpty) {
                          newFiles.addAll(files);
                          onChanged();
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to pick file: $e')),
                        );
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
                  final fileName = _fileNameFromPath(path);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_fileIconForName(fileName)),
                    title: Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
            ...newFiles.map(
              (file) {
                final fileName = _fileNameFromPath(file.path);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_fileIconForName(fileName)),
                  title: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: !enabled
                        ? null
                        : () {
                            newFiles.remove(file);
                            onChanged();
                          },
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isNotEmpty ? parts.last : path;
  }

  IconData _fileIconForName(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'].contains(ext)) {
      return Icons.image_outlined;
    }
    if (['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'm4v'].contains(ext)) {
      return Icons.videocam_outlined;
    }
    if (['pdf'].contains(ext)) {
      return Icons.picture_as_pdf_outlined;
    }
    if (['doc', 'docx', 'rtf', 'txt'].contains(ext)) {
      return Icons.description_outlined;
    }
    if (['xls', 'xlsx', 'csv'].contains(ext)) {
      return Icons.table_chart_outlined;
    }
    if (['ppt', 'pptx'].contains(ext)) {
      return Icons.slideshow_outlined;
    }
    return Icons.insert_drive_file_outlined;
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
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
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
            const Expanded(
              child: Text(
                'Videos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
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
