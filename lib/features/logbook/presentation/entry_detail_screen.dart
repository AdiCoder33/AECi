import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/application/auth_controller.dart';
import '../application/logbook_providers.dart';
import '../domain/elog_entry.dart';
import '../domain/surgical_learning_options.dart';
import '../data/media_repository.dart';
import '../../quality/data/quality_repository.dart';
import '../../teaching/application/teaching_controller.dart';

final _isEditingProvider = StateProvider.autoDispose<bool>((ref) => false);

class EntryDetailScreen extends ConsumerStatefulWidget {
  const EntryDetailScreen({super.key, required this.entryId});

  final String entryId;

  @override
  ConsumerState<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends ConsumerState<EntryDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recordPatientNameController = TextEditingController();
  final _patientController = TextEditingController();
  final _mrnController = TextEditingController();
  final _recordAgeController = TextEditingController();
  final _recordDiagnosisController = TextEditingController();
  final _recordAssistedByController = TextEditingController();
  final _recordDurationController = TextEditingController();
  final _recordSurgicalNotesController = TextEditingController();
  final _recordComplicationsController = TextEditingController();
  final _learningStepController = TextEditingController();
  final _consultantController = TextEditingController();
  
  String? _recordSex;
  String? _recordSurgery;
  String? _recordRightEye;
  String? _recordLeftEye;
  String? _learningSurgery;
  List<String> _existingRecordPreOpImagePaths = [];
  List<String> _existingRecordPostOpImagePaths = [];
  List<String> _existingVideosPaths = [];
  final List<File> _newRecordPreOpImages = [];
  final List<File> _newRecordPostOpImages = [];
  final List<File> _newVideos = [];

  final List<String> _surgeryOptions = [
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

  @override
  void dispose() {
    _recordPatientNameController.dispose();
    _patientController.dispose();
    _mrnController.dispose();
    _recordAgeController.dispose();
    _recordDiagnosisController.dispose();
    _recordAssistedByController.dispose();
    _recordDurationController.dispose();
    _recordSurgicalNotesController.dispose();
    _recordComplicationsController.dispose();
    _learningStepController.dispose();
    _consultantController.dispose();
    super.dispose();
  }

  void _loadEntryForEditing(ElogEntry entry) {
    final payload = entry.payload;
    _patientController.text = entry.patientUniqueId;
    _mrnController.text = entry.mrn;
    
    if (entry.moduleType == moduleRecords) {
      _recordPatientNameController.text = payload['patientName'] ?? '';
      _recordAgeController.text = payload['age']?.toString() ?? '';
      final sex = payload['sex'] as String? ?? '';
      _recordSex = sex.isEmpty
          ? null
          : '${sex[0].toUpperCase()}${sex.substring(1).toLowerCase()}';
      _recordDiagnosisController.text =
          payload['diagnosis'] ?? payload['preOpDiagnosisOrPathology'] ?? '';
      _recordSurgery =
          payload['surgery'] ?? payload['learningPointOrComplication'];
      _recordAssistedByController.text =
          payload['assistedBy'] ?? payload['surgeonOrAssistant'] ?? '';
      _recordDurationController.text = payload['duration'] ?? '';
      _recordRightEye = payload['rightEye'] as String?;
      _recordLeftEye = payload['leftEye'] as String?;
      _recordSurgicalNotesController.text = payload['surgicalNotes'] ?? '';
      _recordComplicationsController.text = payload['complications'] ?? '';
      _existingRecordPreOpImagePaths =
          List<String>.from(payload['preOpImagePaths'] ?? []);
      _existingRecordPostOpImagePaths =
          List<String>.from(payload['postOpImagePaths'] ?? []);
    } else if (entry.moduleType == moduleLearning) {
      _learningSurgery = payload['surgery'] ?? payload['preOpDiagnosisOrPathology'];
      _learningStepController.text = payload['stepName'] ?? payload['teachingPoint'] ?? '';
      _consultantController.text = payload['consultantName'] ?? payload['surgeon'] ?? '';
      _existingVideosPaths = List<String>.from(payload['videoPaths'] ?? []);
    }
  }

  Future<void> _saveEntry(ElogEntry entry) async {
    if (!_formKey.currentState!.validate()) return;
    
    final mediaRepo = ref.read(mediaRepositoryProvider);
    Map<String, dynamic> updatedPayload;
    
    if (entry.moduleType == moduleRecords) {
      // Upload new images for records
      List<String> preOpPaths = [..._existingRecordPreOpImagePaths];
      List<String> postOpPaths = [..._existingRecordPostOpImagePaths];
      
      for (final file in _newRecordPreOpImages) {
        final path = await mediaRepo.uploadImage(entryId: entry.id, file: file);
        preOpPaths.add(path);
      }
      
      for (final file in _newRecordPostOpImages) {
        final path = await mediaRepo.uploadImage(entryId: entry.id, file: file);
        postOpPaths.add(path);
      }
      
      updatedPayload = {
        ...entry.payload,
        'patientName': _recordPatientNameController.text,
        'age': int.tryParse(_recordAgeController.text) ?? 0,
        'sex': _recordSex?.toLowerCase() ?? '',
        'diagnosis': _recordDiagnosisController.text,
        'surgery': _recordSurgery ?? '',
        'assistedBy': _recordAssistedByController.text,
        'duration': _recordDurationController.text,
        'rightEye': _recordRightEye ?? '',
        'leftEye': _recordLeftEye ?? '',
        'surgicalNotes': _recordSurgicalNotesController.text,
        'complications': _recordComplicationsController.text,
        'preOpImagePaths': preOpPaths,
        'postOpImagePaths': postOpPaths,
      };
    } else if (entry.moduleType == moduleLearning) {
      // Upload new videos for learning
      List<String> videoPaths = [..._existingVideosPaths];
      
      for (final file in _newVideos) {
        final path = await mediaRepo.uploadImage(entryId: entry.id, file: file);
        videoPaths.add(path);
      }
      
      updatedPayload = {
        ...entry.payload,
        'surgery': _learningSurgery ?? '',
        'stepName': _learningStepController.text,
        'consultantName': _consultantController.text,
        'videoPaths': videoPaths,
      };
    } else {
      updatedPayload = entry.payload;
    }

    final update = ElogEntryUpdate(
      patientUniqueId: _patientController.text,
      mrn: _mrnController.text,
      payload: updatedPayload,
    );

    await ref.read(entryMutationProvider.notifier).update(entry.id, update);
    ref.invalidate(entryDetailProvider(widget.entryId));
    ref.read(_isEditingProvider.notifier).state = false;
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final entryAsync = ref.watch(entryDetailProvider(widget.entryId));
    final auth = ref.watch(authControllerProvider);
    final isEditing = ref.watch(_isEditingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          isEditing ? 'Edit Entry' : 'Entry Detail',
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: entryAsync.when(
        data: (entry) {
          final isOwner = auth.session?.user.id == entry.createdBy;
          final canEdit = isOwner &&
              (entry.status == statusDraft || entry.status == statusNeedsRevision);
          
          // For surgical records or learning, show edit form
          if ((entry.moduleType == moduleRecords || entry.moduleType == moduleLearning) && isEditing && canEdit) {
            if (entry.moduleType == moduleRecords && _recordPatientNameController.text.isEmpty) {
              _loadEntryForEditing(entry);
            } else if (entry.moduleType == moduleLearning && _learningStepController.text.isEmpty) {
              _loadEntryForEditing(entry);
            }
            return _buildEditForm(entry, canEdit);
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add Edit Button for surgical records and learning
                if ((entry.moduleType == moduleRecords || entry.moduleType == moduleLearning) && canEdit && !isEditing) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref.read(_isEditingProvider.notifier).state = true;
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Entry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B5FFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B5FFF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.description,
                              color: Color(0xFF0B5FFF),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.patientUniqueId,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'MRN: ${entry.mrn}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _StatusBadge(status: entry.status),
                          const Spacer(),
                          Text(
                            'Updated ${_formatDate(entry.updatedAt)}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.category_outlined,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              entry.moduleType,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (entry.keywords.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: entry.keywords
                              .map(
                                (k) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    k,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _AuthorInfo(author: entry.authorProfile),
                const SizedBox(height: 12),
                _PayloadView(entry: entry),
                const SizedBox(height: 12),
                _QualitySection(entry: entry),
                const SizedBox(height: 12),
                _ReviewPanel(entry: entry),
                const SizedBox(height: 12),
                _SimilarEntries(entry: entry),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                if (entry.status == statusApproved)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final note = await showDialog<String>(
                          context: context,
                          builder: (_) {
                            final controller = TextEditingController();
                            return AlertDialog(
                              title: const Text('Propose to Teaching Library'),
                              content: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  hintText: 'Optional note',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context, rootNavigator: true)
                                          .pop(null),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context, rootNavigator: true)
                                          .pop(controller.text.trim()),
                                  child: const Text('Submit'),
                                ),
                              ],
                            );
                          },
                        );
                        if (note != null) {
                          try {
                            await ref
                                .read(teachingMutationProvider.notifier)
                                .propose(entry.id, note);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Proposal submitted')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text('Failed: $e')));
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.school, color: Colors.white),
                      label: const Text(
                        'Propose to Teaching Library',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                if (canEdit)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => context.pushNamed(
                          'logbookEdit',
                          pathParameters: {'id': entry.id},
                          extra: entry.moduleType,
                        ),
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text(
                          'Edit',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B5FFF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: entry.status == statusDraft
                            ? () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete entry?'),
                                    content: const Text(
                                      'This will remove the entry permanently.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context, rootNavigator: true)
                                                .pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context, rootNavigator: true)
                                                .pop(true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  await ref
                                      .read(entryMutationProvider.notifier)
                                      .delete(entry.id);
                                  if (context.mounted) {
                                    context.go('/logbook');
                                  }
                                }
                              }
                            : null,
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(
                          'Delete Draft',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (!canEdit && isOwner)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Editing locked while submitted/approved/rejected. You can edit after consultant requests changes.',
                            style: TextStyle(
                              color: Color(0xFF92400E),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF0B5FFF),
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load entry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditForm(ElogEntry entry, bool canEdit) {
    final isRecords = entry.moduleType == moduleRecords;
    final isLearning = entry.moduleType == moduleLearning;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isRecords) ...[
              _buildTextField(
                controller: _recordPatientNameController,
                label: 'Patient name',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _patientController,
                label: 'UID',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _mrnController,
                label: 'MRN',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _recordAgeController,
              label: 'Age',
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildSexDropdown(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _recordDiagnosisController,
              label: 'Diagnosis',
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildSurgeryDropdown(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _recordAssistedByController,
              label: 'Assisted by',
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _recordDurationController,
              label: 'Duration',
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            _buildEyeDropdownRow(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _recordSurgicalNotesController,
              label: 'Surgical notes',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _recordComplicationsController,
              label: 'Complications',
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _ImagePickerSection(
              title: 'Pre-op images',
              existingPaths: _existingRecordPreOpImagePaths,
              newImages: _newRecordPreOpImages,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 16),
            _ImagePickerSection(
              title: 'Post-op images',
              existingPaths: _existingRecordPostOpImagePaths,
              newImages: _newRecordPostOpImages,
              onChanged: () => setState(() {}),
            ),
            ] else if (isLearning) ...[
              _buildLearningSurgeryDropdown(),
              const SizedBox(height: 16),
              _buildLearningStepDropdown(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _consultantController,
                label: 'Consultant name',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              _VideoPickerSection(
                title: 'Videos',
                existingPaths: _existingVideosPaths,
                newVideos: _newVideos,
                onChanged: () => setState(() {}),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _saveEntry(entry),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B5FFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(_isEditingProvider.notifier).state = false;
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Color(0xFF0B5FFF)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _buildSexDropdown() {
    return DropdownButtonFormField<String>(
      value: _recordSex,
      decoration: InputDecoration(
        labelText: 'Sex',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: ['Male', 'Female', 'Other']
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (value) => setState(() => _recordSex = value),
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _buildSurgeryDropdown() {
    const surgeryOptions = [
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
    
    return DropdownButtonFormField<String>(
      value: _recordSurgery,
      decoration: InputDecoration(
        labelText: 'Surgery',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: surgeryOptions
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (value) => setState(() => _recordSurgery = value),
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _buildEyeDropdownRow() {
    const eyeOptions = ['Operated', 'Not operated'];
    
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _recordRightEye,
            decoration: InputDecoration(
              labelText: 'Right eye',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            items: eyeOptions
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) => setState(() => _recordRightEye = value),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _recordLeftEye,
            decoration: InputDecoration(
              labelText: 'Left eye',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            items: eyeOptions
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) => setState(() => _recordLeftEye = value),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return date.toLocal().toString().split(' ')[0];
    }
  }

  List<Widget> _buildDetailRows(ElogEntry entry) {
    final payload = entry.payload;
    final rows = <Widget>[];
    
    switch (entry.moduleType) {
      case moduleImages:
        final mediaType = payload['mediaType'] ?? '';
        final diagnosis = payload['diagnosis'] ?? payload['keyDescriptionOrPathology'] ?? '';
        final brief = payload['briefDescription'] ?? payload['additionalInformation'] ?? '';
        
        if (mediaType.toString().isNotEmpty) {
          rows.add(_DetailRow(
            icon: Icons.category_outlined,
            label: 'Type of media',
            value: mediaType.toString(),
          ));
        }
        if (diagnosis.toString().isNotEmpty) {
          rows.add(_DetailRow(
            icon: Icons.medical_information_outlined,
            label: 'Diagnosis',
            value: diagnosis.toString(),
          ));
        }
        if (brief.toString().isNotEmpty) {
          rows.add(_DetailRow(
            icon: Icons.description_outlined,
            label: 'Brief description',
            value: brief.toString(),
          ));
        }
        break;
        
      case moduleCases:
        final briefDesc = payload['briefDescription'] ?? '';
        if (briefDesc.toString().isNotEmpty) {
          rows.add(_DetailRow(
            icon: Icons.description_outlined,
            label: 'Brief description',
            value: briefDesc.toString(),
          ));
        }
        final followUp = payload['followUpVisitDescription'] ?? '';
        if (followUp.toString().isNotEmpty) {
          rows.add(_DetailRow(
            icon: Icons.follow_the_signs_outlined,
            label: 'Follow up',
            value: followUp.toString(),
          ));
        }
        break;
        
      case moduleRecords:
        final patientName = payload['patientName'] ?? '';
        final age = payload['age']?.toString() ?? '';
        final sex = payload['sex'] ?? '';
        final diagnosis = payload['diagnosis'] ?? payload['preOpDiagnosisOrPathology'] ?? '';
        final surgery = payload['surgery'] ?? payload['learningPointOrComplication'] ?? '';
        final assistedBy = payload['assistedBy'] ?? payload['surgeonOrAssistant'] ?? '';
        final duration = payload['duration'] ?? '';
        final rightEye = payload['rightEye'] ?? '';
        final leftEye = payload['leftEye'] ?? '';
        final surgicalNotes = payload['surgicalNotes'] ?? '';
        final complications = payload['complications'] ?? '';
        
        if (patientName.toString().isNotEmpty) {
          rows.add(_DetailRow(
            icon: Icons.person_outline,
            label: 'Patient name',
            value: patientName.toString(),
          ));
        }
        if (age.toString().isNotEmpty) {
          rows.add(_DetailRow(
            icon: Icons.cake_outlined,
            label: 'Age',
            value: age.toString(),
          ));
        }
        if (sex.toString().isNotEmpty) {
          rows.add(_DetailRow(
            icon: Icons.wc_outlined,
            label: 'Sex',
            value: sex.toString(),
          ));
        }
        if (diagnosis.toString().isNotEmpty) {
          rows.add(_DetailRow(
            icon: Icons.medical_information_outlined,
            label: 'Diagnosis',
            value: diagnosis.toString(),
          ));
        }
        if (surgery.toString().isNotEmpty) {
          rows.add(_DetailRow(
            icon: Icons.medical_services_outlined,
            label: 'Surgery',
            value: surgery.toString(),
          ));
        }
        if (assistedBy.toString().isNotEmpty) {
          rows.add(_DetailRow(
            icon: Icons.people_outline,
            label: 'Assisted by',
            value: assistedBy.toString(),
          ));
        }
        if (duration.toString().isNotEmpty) {
          rows.add(_DetailRow(
            icon: Icons.timer_outlined,
            label: 'Duration',
            value: duration.toString(),
          ));
        }
        if (rightEye.toString().isNotEmpty) {
          rows.add(_DetailRow(
            icon: Icons.visibility_outlined,
            label: 'Right eye',
            value: rightEye.toString(),
          ));
        }
        if (leftEye.toString().isNotEmpty) {
          rows.add(_DetailRow(
            icon: Icons.visibility_outlined,
            label: 'Left eye',
            value: leftEye.toString(),
          ));
        }
        if (surgicalNotes.toString().isNotEmpty) {
          rows.add(_DetailRow(
            icon: Icons.note_outlined,
            label: 'Surgical notes',
            value: surgicalNotes.toString(),
          ));
        }
        if (complications.toString().isNotEmpty) {
          rows.add(_DetailRow(
            icon: Icons.warning_amber_outlined,
            label: 'Complications',
            value: complications.toString(),
          ));
        }
        break;
        
      default:
        break;
    }
    
    return rows;
  }

  Widget _buildLearningSurgeryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Surgery *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _learningSurgery,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            hint: const Text('Select surgery'),
            items: _surgeryOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _learningSurgery = newValue;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLearningStepDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Teaching Point / Step Name *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: surgicalLearningOptions.contains(_learningStepController.text)
                ? _learningStepController.text
                : null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            hint: const Text('Select or enter step name'),
            items: surgicalLearningOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                _learningStepController.text = newValue;
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        // Allow custom entry
        if (_learningStepController.text.isNotEmpty &&
            !surgicalLearningOptions.contains(_learningStepController.text))
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Custom step: ${_learningStepController.text}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF0B5FFF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagesSection extends ConsumerWidget {
  const _ImagesSection({required this.entry});

  final ElogEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedCache = ref.read(signedUrlCacheProvider.notifier);
    final payload = entry.payload;
    
    List<String> imagePaths = [];
    List<String> preOpPaths = [];
    List<String> postOpPaths = [];
    
    if (entry.moduleType == moduleCases) {
      imagePaths = [
        ...List<String>.from(payload['ancillaryImagingPaths'] ?? []),
        ...List<String>.from(payload['followUpVisitImagingPaths'] ?? []),
      ];
    } else if (entry.moduleType == moduleImages) {
      imagePaths = [
        ...List<String>.from(payload['uploadImagePaths'] ?? []),
        ...List<String>.from(payload['followUpVisitImagingPaths'] ?? []),
      ];
    } else if (entry.moduleType == moduleRecords) {
      preOpPaths = List<String>.from(payload['preOpImagePaths'] ?? []);
      postOpPaths = List<String>.from(payload['postOpImagePaths'] ?? []);
    }
    
    if (imagePaths.isEmpty && preOpPaths.isEmpty && postOpPaths.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        if (imagePaths.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildImageGrid(context, ref, signedCache, 'Images', imagePaths),
          ),
        if (preOpPaths.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildImageGrid(context, ref, signedCache, 'Pre-op images', preOpPaths),
          ),
        ],
        if (postOpPaths.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildImageGrid(context, ref, signedCache, 'Post-op images', postOpPaths),
          ),
        ],
      ],
    );
  }

  Widget _buildImageGrid(
    BuildContext context,
    WidgetRef ref,
    dynamic signedCache,
    String title,
    List<String> imagePaths,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0B5FFF),
                    const Color(0xFF0B5FFF).withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.image_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$title (${imagePaths.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: imagePaths.length,
          itemBuilder: (context, index) {
            final path = imagePaths[index];
            return FutureBuilder<String>(
              future: signedCache.getUrl(path),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0B5FFF),
                      ),
                    ),
                  );
                }
                return GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: Stack(
                        children: [
                          Center(
                            child: InteractiveViewer(
                              child: Image.network(snapshot.data!),
                            ),
                          ),
                          Positioned(
                            top: 20,
                            right: 20,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close, color: Colors.white, size: 30),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        snapshot.data!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _AuthorInfo extends StatelessWidget {
  const _AuthorInfo({this.author});

  final Map<String, dynamic>? author;

  @override
  Widget build(BuildContext context) {
    if (author == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF0B5FFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Author',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoItem('Name', author?['name'] ?? ''),
          const SizedBox(height: 8),
          _InfoItem('Designation', author?['designation'] ?? ''),
          const SizedBox(height: 8),
          _InfoItem('Centre', author?['centre'] ?? ''),
          const SizedBox(height: 8),
          _InfoItem('Employee ID', author?['employee_id'] ?? ''),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _PayloadView extends ConsumerWidget {
  const _PayloadView({required this.entry});

  final ElogEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payload = entry.payload;
    final signedCache = ref.read(signedUrlCacheProvider.notifier);

    List<String> imagePaths = [];
    if (entry.moduleType == moduleCases) {
      imagePaths = [
        ...List<String>.from(payload['ancillaryImagingPaths'] ?? []),
        ...List<String>.from(payload['followUpVisitImagingPaths'] ?? []),
      ];
    } else if (entry.moduleType == moduleImages) {
      imagePaths = [
        ...List<String>.from(payload['uploadImagePaths'] ?? []),
        ...List<String>.from(payload['followUpVisitImagingPaths'] ?? []),
      ];
    }
    final recordPreOpPaths =
        List<String>.from(payload['preOpImagePaths'] ?? []);
    final recordPostOpPaths =
        List<String>.from(payload['postOpImagePaths'] ?? []);

    final videoLink = payload['surgicalVideoLink'] as String?;
    final videoPaths = List<String>.from(payload['videoPaths'] ?? []);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.article_outlined,
                color: Color(0xFF0B5FFF),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._buildFields(entry),
          if (videoLink != null && videoLink.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse(videoLink)),
              icon: const Icon(Icons.play_circle_outline, color: Color(0xFF0B5FFF)),
              label: const Text(
                'Open Video Link',
                style: TextStyle(
                  color: Color(0xFF0B5FFF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                side: const BorderSide(color: Color(0xFF0B5FFF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
          if (videoPaths.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Videos',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...videoPaths.map(
              (path) => FutureBuilder<String>(
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
          ],
          if (imagePaths.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Images',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _ImageGrid(paths: imagePaths),
          ],
          if (entry.moduleType == moduleRecords &&
              recordPreOpPaths.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Pre-op images',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _ImageGrid(paths: recordPreOpPaths),
          ],
          if (entry.moduleType == moduleRecords &&
              recordPostOpPaths.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Post-op images',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _ImageGrid(paths: recordPostOpPaths),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildFields(ElogEntry entry) {
    final payload = entry.payload;
    switch (entry.moduleType) {
      case moduleCases:
        return [
          _FieldRow('Brief description', payload['briefDescription'] ?? ''),
          if ((payload['followUpVisitDescription'] ?? '').toString().isNotEmpty)
            _FieldRow('Follow up', payload['followUpVisitDescription']),
        ];
      case moduleImages:
        final diagnosis =
            payload['diagnosis'] ?? payload['keyDescriptionOrPathology'] ?? '';
        final brief =
            payload['briefDescription'] ?? payload['additionalInformation'] ?? '';
        final mediaType = payload['mediaType'] ?? '';
        final keywords = entry.keywords;
        return [
          if (mediaType.toString().isNotEmpty)
            _FieldRow('Type of media', mediaType.toString()),
          _FieldRow('Diagnosis', diagnosis.toString()),
          _FieldRow('Brief description', brief.toString()),
          if (keywords.isNotEmpty)
            _FieldRow('Keywords', keywords.join(', ')),
          if ((payload['additionalInformation'] ?? '').toString().isNotEmpty &&
              payload['additionalInformation'] != payload['briefDescription'])
            _FieldRow('Additional info', payload['additionalInformation']),
        ];
      case moduleLearning:
        final surgery =
            payload['surgery'] ?? payload['preOpDiagnosisOrPathology'] ?? '';
        final step = payload['stepName'] ?? payload['teachingPoint'] ?? '';
        final consultant =
            payload['consultantName'] ?? payload['surgeon'] ?? '';
        return [
          _FieldRow('Name of the surgery', surgery.toString()),
          _FieldRow('Name of the step', step.toString()),
          _FieldRow('Consultant name', consultant.toString()),
        ];
      case moduleRecords:
        final patientName = payload['patientName'] ?? '';
        final age = payload['age']?.toString() ?? '';
        final sex = payload['sex'] ?? '';
        final diagnosis =
            payload['diagnosis'] ?? payload['preOpDiagnosisOrPathology'] ?? '';
        final surgery =
            payload['surgery'] ?? payload['learningPointOrComplication'] ?? '';
        final assistedBy =
            payload['assistedBy'] ?? payload['surgeonOrAssistant'] ?? '';
        final duration = payload['duration'] ?? '';
        final rightEye = payload['rightEye'] ?? '';
        final leftEye = payload['leftEye'] ?? '';
        final surgicalNotes = payload['surgicalNotes'] ?? '';
        final complications = payload['complications'] ?? '';
        return [
          if (patientName.toString().isNotEmpty)
            _FieldRow('Patient name', patientName.toString()),
          if (age.toString().isNotEmpty) _FieldRow('Age', age.toString()),
          if (sex.toString().isNotEmpty) _FieldRow('Sex', sex.toString()),
          _FieldRow('Diagnosis', diagnosis.toString()),
          _FieldRow('Surgery', surgery.toString()),
          _FieldRow('Assisted by', assistedBy.toString()),
          _FieldRow('Duration', duration.toString()),
          if (rightEye.toString().isNotEmpty)
            _FieldRow('Right eye', rightEye.toString()),
          if (leftEye.toString().isNotEmpty)
            _FieldRow('Left eye', leftEye.toString()),
          if (surgicalNotes.toString().isNotEmpty)
            _FieldRow('Surgical notes', surgicalNotes.toString()),
          if (complications.toString().isNotEmpty)
            _FieldRow('Complications', complications.toString()),
        ];
      default:
        return [];
    }
  }
}

class _ImageGrid extends ConsumerWidget {
  const _ImageGrid({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedCache = ref.read(signedUrlCacheProvider.notifier);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: paths.length,
      itemBuilder: (context, index) {
        final path = paths[index];
        return FutureBuilder<String>(
          future: signedCache.getUrl(path),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0B5FFF),
                  ),
                ),
              );
            }
            return GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => Dialog(
                  child: InteractiveViewer(
                    child: Image.network(snapshot.data!),
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(snapshot.data!, fit: BoxFit.cover),
              ),
            );
          },
        );
      },
    );
  }
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({required this.entry});

  final ElogEntry entry;

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (entry.status == statusSubmitted && entry.reviewedAt == null) {
      body = Row(
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 20,
            color: Colors.orange[400],
          ),
          const SizedBox(width: 8),
          const Text(
            'Awaiting consultant review',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
        ],
      );
    } else if (entry.reviewedAt != null) {
      final reviewerName = entry.reviewerProfile != null
          ? entry.reviewerProfile!['name']
          : entry.reviewedBy;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoItem('Reviewer', reviewerName ?? ''),
          const SizedBox(height: 8),
          _InfoItem('Decision', entry.status),
          if (entry.reviewComment != null && entry.reviewComment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 16,
                        color: Color(0xFF0B5FFF),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Comment',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.reviewComment!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (entry.requiredChanges.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Required changes:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            ...entry.requiredChanges.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.checklist_rtl,
                      size: 16,
                      color: Color(0xFF0B5FFF),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (entry.reviewedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Reviewed ${_formatDate(entry.reviewedAt!)}',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
              ),
            ),
          ],
        ],
      );
    } else {
      body = const Text(
        'No review yet',
        style: TextStyle(
          color: Color(0xFF64748B),
          fontSize: 14,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.rate_review_outlined,
                color: Color(0xFF0B5FFF),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Review',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return date.toLocal().toString().split(' ')[0];
    }
  }
}

class _QualitySection extends ConsumerWidget {
  const _QualitySection({required this.entry});
  final ElogEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                color: Color(0xFF0B5FFF),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Quality',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Score: ${entry.qualityScore ?? 0}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B5FFF),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(qualityRepositoryProvider).scoreEntry(entry.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Re-scored entry')),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  side: const BorderSide(color: Color(0xFF0B5FFF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Re-score',
                  style: TextStyle(
                    color: Color(0xFF0B5FFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (entry.qualityIssues.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFF59E0B),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Color(0xFFD97706),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Issues Detected',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...entry.qualityIssues.map(
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              i,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Color(0xFF059669),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'No issues detected',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF065F46),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SimilarEntries extends ConsumerWidget {
  const _SimilarEntries({required this.entry});
  final ElogEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(qualityRepositoryProvider);
    return FutureBuilder(
      future: repo.similarEntries(entry),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF0B5FFF),
            ),
          );
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.compare_arrows,
                    color: Color(0xFF0B5FFF),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Similar Entries',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...list.map(
                (e) => InkWell(
                  onTap: () => context.pushNamed(
                    'logbookDetail',
                    pathParameters: {'id': e.id},
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.patientUniqueId,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        if (e.keywords.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: e.keywords.take(3).map(
                              (k) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  k,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  Color _color() {
    switch (status) {
      case statusApproved:
        return const Color(0xFF10B981);
      case statusSubmitted:
        return const Color(0xFF0B5FFF);
      case statusNeedsRevision:
        return const Color(0xFFF59E0B);
      case statusRejected:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _icon() {
    switch (status) {
      case statusApproved:
        return Icons.check_circle;
      case statusSubmitted:
        return Icons.send;
      case statusNeedsRevision:
        return Icons.edit_note;
      case statusRejected:
        return Icons.cancel;
      default:
        return Icons.article_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _color().withOpacity(0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon(),
            size: 16,
            color: _color(),
          ),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _color(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePickerSection extends StatelessWidget {
  const _ImagePickerSection({
    required this.title,
    required this.existingPaths,
    required this.newImages,
    required this.onChanged,
  });

  final String title;
  final List<String> existingPaths;
  final List<File> newImages;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                final picker = ImagePicker();
                final images = await picker.pickMultiImage();
                if (images.isNotEmpty) {
                  newImages.addAll(images.map((i) => File(i.path)));
                  onChanged();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0B5FFF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (existingPaths.isEmpty && newImages.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ),
            ),
            child: const Center(
              child: Text(
                'No images added',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...existingPaths.map((path) => _ExistingImageChip(
                    path: path,
                    onRemove: () {
                      existingPaths.remove(path);
                      onChanged();
                    },
                  )),
              ...newImages.map((file) => _NewImageChip(
                    file: file,
                    onRemove: () {
                      newImages.remove(file);
                      onChanged();
                    },
                  )),
            ],
          ),
      ],
    );
  }
}

class _ExistingImageChip extends ConsumerWidget {
  const _ExistingImageChip({
    required this.path,
    required this.onRemove,
  });

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedCache = ref.read(signedUrlCacheProvider.notifier);
    return FutureBuilder<String>(
      future: signedCache.getUrl(path),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return Stack(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(snapshot.data!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NewImageChip extends StatelessWidget {
  const _NewImageChip({
    required this.file,
    required this.onRemove,
  });

  final File file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: FileImage(file),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VideoPickerSection extends StatelessWidget {
  const _VideoPickerSection({
    required this.title,
    required this.existingPaths,
    required this.newVideos,
    required this.onChanged,
  });

  final String title;
  final List<String> existingPaths;
  final List<File> newVideos;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                final picker = ImagePicker();
                final video = await picker.pickVideo(source: ImageSource.gallery);
                if (video != null) {
                  newVideos.add(File(video.path));
                  onChanged();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0B5FFF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (existingPaths.isEmpty && newVideos.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ),
            ),
            child: const Center(
              child: Text(
                'No videos added',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              ...existingPaths.map((path) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.videocam, color: Color(0xFF0B5FFF)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              path.split('/').last,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red, size: 20),
                            onPressed: () {
                              existingPaths.remove(path);
                              onChanged();
                            },
                          ),
                        ],
                      ),
                    ),
                  )),
              ...newVideos.map((file) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF0B5FFF)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.videocam, color: Color(0xFF0B5FFF)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              file.path.split('/').last,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Chip(
                            label: Text('New', style: TextStyle(fontSize: 11)),
                            backgroundColor: Color(0xFFDCFCE7),
                            labelPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red, size: 20),
                            onPressed: () {
                              newVideos.remove(file);
                              onChanged();
                            },
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
      ],
    );
  }
}

