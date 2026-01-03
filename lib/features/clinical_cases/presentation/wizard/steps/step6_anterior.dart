import 'package:flutter/material.dart';

import '../../../domain/constants/anterior_segment_options.dart';
import '../../widgets/taxonomy_multi_select_field.dart';

class Step6Anterior extends StatelessWidget {
  const Step6Anterior({
    super.key,
    required this.formKey,
    required this.anterior,
    required this.onSelectionChanged,
    required this.onDescriptionChanged,
    required this.onOtherChanged,
    required this.onRemarksChanged,
  });

  final GlobalKey<FormState> formKey;
  final Map<String, dynamic> anterior;
  final void Function(String eye, String sectionKey, List<String> selected)
  onSelectionChanged;
  final void Function(
    String eye,
    String sectionKey,
    String option,
    String description,
  )
  onDescriptionChanged;
  final void Function(String eye, String sectionKey, String other)
  onOtherChanged;
  final void Function(String eye, String remarks) onRemarksChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Set All Normal Button
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton.icon(
              onPressed: () => _setAllNormal(),
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: const Text(
                'Set All Normal',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Gradient Header for RE
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.remove_red_eye,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Right Eye (RE)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _EyeSection(
                          title: 'RE',
                          eyeKey: 'RE',
                          anterior: anterior,
                          onSelectionChanged: onSelectionChanged,
                          onDescriptionChanged: onDescriptionChanged,
                          onOtherChanged: onOtherChanged,
                          onRemarksChanged: onRemarksChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Gradient Header for LE
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF06B6D4), Color(0xFF22D3EE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.remove_red_eye,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Left Eye (LE)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _EyeSection(
                          title: 'LE',
                          eyeKey: 'LE',
                          anterior: anterior,
                          onSelectionChanged: onSelectionChanged,
                          onDescriptionChanged: onDescriptionChanged,
                          onOtherChanged: onOtherChanged,
                          onRemarksChanged: onRemarksChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _setAllNormal() {
    // Map of section keys to their normal values
    final normalValues = {
      'lids': ['Normal'],
      'conjunctiva': ['Normal'],
      'cornea': ['Clear'],
      'anterior_chamber': ['Quiet', 'Normal Depth'],
      'iris': ['Normal colour and pattern'],
      'pupil': ['Normal size and reaction to light'],
      'lens': ['Clear'],
      'ocular_movements': ['Full and free'],
      'corneal_reflex': ['Normal'],
      'globe': ['Normal'],
    };

    // Set all anterior segment sections to their normal values for both eyes
    for (final section in anteriorSegmentSections) {
      final normalValue = normalValues[section.key] ?? ['Normal'];
      onSelectionChanged('RE', section.key, normalValue);
      onSelectionChanged('LE', section.key, normalValue);
    }
  }
}

class _EyeSection extends StatefulWidget {
  const _EyeSection({
    required this.title,
    required this.eyeKey,
    required this.anterior,
    required this.onSelectionChanged,
    required this.onDescriptionChanged,
    required this.onOtherChanged,
    required this.onRemarksChanged,
  });

  final String title;
  final String eyeKey;
  final Map<String, dynamic> anterior;
  final void Function(String eye, String sectionKey, List<String> selected)
  onSelectionChanged;
  final void Function(
    String eye,
    String sectionKey,
    String option,
    String description,
  )
  onDescriptionChanged;
  final void Function(String eye, String sectionKey, String other)
  onOtherChanged;
  final void Function(String eye, String remarks) onRemarksChanged;

  @override
  State<_EyeSection> createState() => _EyeSectionState();
}

class _EyeSectionState extends State<_EyeSection> {
  final Map<String, bool> _abnormalExpanded = {};

  String _normalOptionForSection(AnteriorSection section) {
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

  bool _isAbnormalSelected(
    String sectionKey,
    List<String> selected,
    String normalOption,
  ) {
    if (selected.contains(normalOption)) return false;
    if (selected.isNotEmpty) return true;
    return _abnormalExpanded['${widget.eyeKey}|$sectionKey'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final eye = Map<String, dynamic>.from(
      widget.anterior[widget.eyeKey] as Map? ?? {},
    );
    final remarks = (eye['remarks'] as String?) ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...anteriorSegmentSections.map((section) {
          final sectionData = Map<String, dynamic>.from(
            eye[section.key] as Map? ?? {},
          );
          final selected =
              (sectionData['selected'] as List?)?.cast<String>() ?? <String>[];
          final descriptions = Map<String, String>.from(
            sectionData['descriptions'] as Map? ?? {},
          );
          final other = (sectionData['other'] as String?) ?? '';
          final normalOption = _normalOptionForSection(section);
          final showOptions = _isAbnormalSelected(
            section.key,
            selected,
            normalOption,
          );
          final abnormalKey = '${widget.eyeKey}|${section.key}';
          final filteredOptions = section.options
              .where((option) => option != normalOption)
              .toList();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Normal'),
                          selected:
                              selected.contains(normalOption) && !showOptions,
                          onSelected: (value) {
                            if (value) {
                              setState(
                                () => _abnormalExpanded[abnormalKey] = false,
                              );
                              widget.onSelectionChanged(
                                widget.eyeKey,
                                section.key,
                                <String>[normalOption],
                              );
                            } else {
                              setState(
                                () => _abnormalExpanded[abnormalKey] = true,
                              );
                              widget.onSelectionChanged(
                                widget.eyeKey,
                                section.key,
                                <String>[],
                              );
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Abnormal'),
                          selected: showOptions,
                          onSelected: (value) {
                            setState(
                              () => _abnormalExpanded[abnormalKey] = value,
                            );
                            if (value && selected.contains(normalOption)) {
                              widget.onSelectionChanged(
                                widget.eyeKey,
                                section.key,
                                <String>[],
                              );
                            } else if (!value) {
                              widget.onSelectionChanged(
                                widget.eyeKey,
                                section.key,
                                <String>[normalOption],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    if (showOptions) ...[
                      const SizedBox(height: 8),
                      TaxonomyMultiSelectField(
                        label: '${section.label} findings',
                        options: filteredOptions,
                        selected: selected
                            .where((o) => o != normalOption)
                            .toList(),
                        descriptions: descriptions,
                        otherValue: other,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Select at least one';
                          }
                          if (value.contains('Normal') && value.length > 1) {
                            return 'Normal must be selected alone';
                          }
                          return null;
                        },
                        onSelectionChanged: (next) => widget.onSelectionChanged(
                          widget.eyeKey,
                          section.key,
                          next,
                        ),
                        onDescriptionChanged: (option, description) =>
                            widget.onDescriptionChanged(
                              widget.eyeKey,
                              section.key,
                              option,
                              description,
                            ),
                        onOtherChanged: (value) => widget.onOtherChanged(
                          widget.eyeKey,
                          section.key,
                          value,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        TextFormField(
          // Use a stable key per eye so typing doesn't rebuild the field.
          key: ValueKey('${widget.eyeKey}-anterior-remarks'),
          initialValue: remarks,
          decoration: const InputDecoration(labelText: 'Remarks (optional)'),
          maxLines: 3,
          onChanged: (value) => widget.onRemarksChanged(widget.eyeKey, value),
        ),
      ],
    );
  }
}
