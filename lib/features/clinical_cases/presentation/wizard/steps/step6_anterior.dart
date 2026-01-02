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
  final void Function(
    String eye,
    String sectionKey,
    List<String> selected,
  ) onSelectionChanged;
  final void Function(
    String eye,
    String sectionKey,
    String option,
    String description,
  ) onDescriptionChanged;
  final void Function(
    String eye,
    String sectionKey,
    String other,
  ) onOtherChanged;
  final void Function(String eye, String remarks) onRemarksChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E5F8C), Color(0xFF2878A8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E5F8C).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.visibility_outlined, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text(
                  'Anterior Segment Examination',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _EyeSection(
                      title: 'Right Eye (RE)',
                      eyeKey: 'RE',
                      anterior: anterior,
                      onSelectionChanged: onSelectionChanged,
                      onDescriptionChanged: onDescriptionChanged,
                      onOtherChanged: onOtherChanged,
                      onRemarksChanged: onRemarksChanged,
                    ),
                  ),
                  Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey[300]!,
                          Colors.grey[200]!,
                          Colors.grey[300]!,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _EyeSection(
                      title: 'Left Eye (LE)',
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
    );
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
  final void Function(
    String eye,
    String sectionKey,
    List<String> selected,
  ) onSelectionChanged;
  final void Function(
    String eye,
    String sectionKey,
    String option,
    String description,
  ) onDescriptionChanged;
  final void Function(
    String eye,
    String sectionKey,
    String other,
  ) onOtherChanged;
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
    final eye =
        Map<String, dynamic>.from(widget.anterior[widget.eyeKey] as Map? ?? {});
    final remarks = (eye['remarks'] as String?) ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1E5F8C).withOpacity(0.1),
                const Color(0xFF2878A8).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1E5F8C).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E5F8C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.remove_red_eye,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E5F8C),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...anteriorSegmentSections.map((section) {
          final sectionData =
              Map<String, dynamic>.from(eye[section.key] as Map? ?? {});
          final selected =
              (sectionData['selected'] as List?)?.cast<String>() ?? <String>[];
          final descriptions =
              Map<String, String>.from(sectionData['descriptions'] as Map? ?? {});
          final other = (sectionData['other'] as String?) ?? '';
          final normalOption = _normalOptionForSection(section);
          final showOptions =
              _isAbnormalSelected(section.key, selected, normalOption);
          final abnormalKey = '${widget.eyeKey}|${section.key}';
          final filteredOptions = section.options
              .where((option) => option != normalOption)
              .toList();
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E5F8C), Color(0xFF2878A8)],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          section.label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Normal'),
                          avatar: selected.contains(normalOption) && !showOptions
                              ? const Icon(Icons.check_circle, size: 18, color: Colors.white)
                              : null,
                          selected: selected.contains(normalOption) &&
                              !showOptions,
                          selectedColor: const Color(0xFF10B981),
                          backgroundColor: Colors.grey[100],
                          labelStyle: TextStyle(
                            color: selected.contains(normalOption) && !showOptions
                                ? Colors.white
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (value) {
                            if (value) {
                              setState(() => _abnormalExpanded[abnormalKey] = false);
                              widget.onSelectionChanged(
                                widget.eyeKey,
                                section.key,
                                <String>[normalOption],
                              );
                            } else {
                              setState(() => _abnormalExpanded[abnormalKey] = true);
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
                          avatar: showOptions
                              ? const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.white)
                              : null,
                          selected: showOptions,
                          selectedColor: const Color(0xFFEF4444),
                          backgroundColor: Colors.grey[100],
                          labelStyle: TextStyle(
                            color: showOptions
                                ? Colors.white
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (value) {
                            setState(() => _abnormalExpanded[abnormalKey] = value);
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
                        selected:
                            selected.where((o) => o != normalOption).toList(),
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
                        onSelectionChanged: (next) =>
                            widget.onSelectionChanged(
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
                        onOtherChanged: (value) =>
                            widget.onOtherChanged(
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
          key: ValueKey('${widget.eyeKey}-anterior-remarks-$remarks'),
          initialValue: remarks,
          decoration: const InputDecoration(
            labelText: 'Remarks (optional)',
          ),
          maxLines: 3,
          onChanged: (value) =>
              widget.onRemarksChanged(widget.eyeKey, value),
        ),
      ],
    );
  }
}
