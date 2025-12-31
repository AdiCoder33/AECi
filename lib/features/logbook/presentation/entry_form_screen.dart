import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../application/logbook_providers.dart';
import '../data/media_repository.dart';
import '../domain/elog_entry.dart';
import '../domain/surgical_learning_options.dart';
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

  final _preOpController = TextEditingController();
  final _surgicalVideoController = TextEditingController();
  final _teachingPointController = TextEditingController();
  final _surgeonController = TextEditingController();
  final _learningPointController = TextEditingController();
  final _surgeonAssistantController = TextEditingController();

  String? _moduleType;
  String _currentStatus = statusDraft;
  List<String> _existingImagePaths = [];
  final List<File> _newImages = [];

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
          _keyDescriptionController.text =
              payload['keyDescriptionOrPathology'] ?? '';
          _additionalInfoController.text =
              payload['additionalInformation'] ?? '';
          _existingImagePaths = [
            ...List<String>.from(payload['uploadImagePaths'] ?? []),
            ...List<String>.from(payload['followUpVisitImagingPaths'] ?? []),
          ];
          break;
        case moduleLearning:
          _preOpController.text = payload['preOpDiagnosisOrPathology'] ?? '';
          _surgicalVideoController.text = payload['surgicalVideoLink'] ?? '';
          _teachingPointController.text = payload['teachingPoint'] ?? '';
          _surgeonController.text = payload['surgeon'] ?? '';
          break;
        case moduleRecords:
          _preOpController.text = payload['preOpDiagnosisOrPathology'] ?? '';
          _surgicalVideoController.text = payload['surgicalVideoLink'] ?? '';
          _learningPointController.text =
              payload['learningPointOrComplication'] ?? '';
          _surgeonAssistantController.text =
              payload['surgeonOrAssistant'] ?? '';
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
    final mutation = ref.watch(entryMutationProvider);

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Entry' : 'New Entry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _moduleType,
                decoration: const InputDecoration(labelText: 'Module'),
                items: moduleTypes
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: isEditing ? null : (value) => setState(() => _moduleType = value),
              ),
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
              const SizedBox(height: 12),
              _ModuleFields(
                moduleType: _moduleType ?? moduleCases,
                briefDescController: _briefDescController,
                followUpDescController: _followUpDescController,
                keyDescriptionController: _keyDescriptionController,
                additionalInfoController: _additionalInfoController,
                preOpController: _preOpController,
                surgicalVideoController: _surgicalVideoController,
                teachingPointController: _teachingPointController,
                surgeonController: _surgeonController,
                learningPointController: _learningPointController,
                surgeonAssistantController: _surgeonAssistantController,
                enabled: _canEditStatus,
              ),
              if (_moduleType == moduleCases || _moduleType == moduleImages)
                _ImagePickerSection(
                  existingPaths: _existingImagePaths,
                  newImages: _newImages,
                  onChanged: () => setState(() {}),
                  enabled: _canEditStatus,
                ),
              if (!_canEditStatus)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Editing locked while submitted/approved/rejected.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: !_canEditStatus || mutation.isLoading
                        ? null
                        : () => _save(submit: false),
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
                            'Save Draft',
                            style: TextStyle(color: Colors.black),
                          ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: !_canEditStatus || mutation.isLoading
                        ? null
                        : () => _save(submit: true),
                    child: const Text(
                      'Submit for review',
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

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  Widget _buildText({
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
    final keywords = _keywordsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final mediaRepo = ref.read(mediaRepositoryProvider);
    Map<String, dynamic> payload = _buildPayload(module);

    try {
      if (widget.entryId == null) {
        final create = ElogEntryCreate(
          moduleType: module,
          patientUniqueId: _patientController.text.trim(),
          mrn: _mrnController.text.trim(),
          keywords: keywords,
          payload: payload,
        );
        final entryId =
            await ref.read(entryMutationProvider.notifier).create(create);

        final newPaths = await _uploadNewImages(mediaRepo, entryId);
        if (newPaths.isNotEmpty) {
          payload = _withNewPaths(module, payload, newPaths);
          await ref
              .read(entryMutationProvider.notifier)
              .update(entryId, ElogEntryUpdate(payload: payload));
        }
        if (submit) {
          await ref.read(entryMutationProvider.notifier).update(
                entryId,
                ElogEntryUpdate(
                  status: statusSubmitted,
                  submittedAt: DateTime.now(),
                  clearReview: true,
                ),
              );
        }
      } else {
        final entryId = widget.entryId!;
        final newPaths = await _uploadNewImages(mediaRepo, entryId);
        if (newPaths.isNotEmpty) {
          payload = _withNewPaths(module, payload, newPaths);
        }
        final update = ElogEntryUpdate(
          patientUniqueId: _patientController.text.trim(),
          mrn: _mrnController.text.trim(),
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
        await ref.read(qualityRepositoryProvider).scoreEntry(
              widget.entryId ?? '',
            );
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
  ) async {
    final newPaths = <String>[];
    for (final file in _newImages) {
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
          'keyDescriptionOrPathology': _keyDescriptionController.text.trim(),
          'additionalInformation': _additionalInfoController.text.trim(),
          'followUpVisitImagingPaths': <String>[],
        };
      case moduleLearning:
        return {
          'preOpDiagnosisOrPathology': _preOpController.text.trim(),
          'surgicalVideoLink': _surgicalVideoController.text.trim(),
          'teachingPoint': _teachingPointController.text.trim(),
          'surgeon': _surgeonController.text.trim(),
        };
      case moduleRecords:
        return {
          'preOpDiagnosisOrPathology': _preOpController.text.trim(),
          'surgicalVideoLink': _surgicalVideoController.text.trim(),
          'learningPointOrComplication': _learningPointController.text.trim(),
          'surgeonOrAssistant': _surgeonAssistantController.text.trim(),
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
}

class _ModuleFields extends StatelessWidget {
  const _ModuleFields({
    required this.moduleType,
    required this.briefDescController,
    required this.followUpDescController,
    required this.keyDescriptionController,
    required this.additionalInfoController,
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
            _buildField(
              controller: keyDescriptionController,
              label: 'Key Description / Pathology',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
              enabled: enabled,
            ),
            _buildField(
              controller: additionalInfoController,
              label: 'Additional Information (optional)',
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
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Required' : null,
        onChanged: enabled ? (v) => controller.text = v ?? '' : null,
      ),
    );
  }
}

class _ImagePickerSection extends ConsumerWidget {
  const _ImagePickerSection({
    required this.existingPaths,
    required this.newImages,
    required this.onChanged,
    required this.enabled,
  });

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
            const Text('Images', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          existing.removeWhere((e) => e.toLowerCase() == last.toLowerCase());
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
