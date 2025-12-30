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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
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
                  const SizedBox(width: 16),
                  Expanded(
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
  bool _showLidsOptions = false;

  @override
  void initState() {
    super.initState();
    _syncLids(force: true);
  }

  @override
  void didUpdateWidget(covariant _EyeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncLids();
  }

  void _syncLids({bool force = false}) {
    final selected = _sectionSelected('lids');
    if (selected.contains('Normal')) {
      _showLidsOptions = false;
      return;
    }
    if (selected.isNotEmpty) {
      _showLidsOptions = true;
      return;
    }
    if (force) {
      _showLidsOptions = false;
    }
  }

  List<String> _sectionSelected(String sectionKey) {
    final eye = Map<String, dynamic>.from(widget.anterior[widget.eyeKey] as Map? ?? {});
    final section =
        Map<String, dynamic>.from(eye[sectionKey] as Map? ?? {});
    return (section['selected'] as List?)?.cast<String>() ?? <String>[];
  }

  @override
  Widget build(BuildContext context) {
    final eye =
        Map<String, dynamic>.from(widget.anterior[widget.eyeKey] as Map? ?? {});
    final remarks = (eye['remarks'] as String?) ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        ...anteriorSegmentSections.map((section) {
          final sectionData =
              Map<String, dynamic>.from(eye[section.key] as Map? ?? {});
          final selected =
              (sectionData['selected'] as List?)?.cast<String>() ?? <String>[];
          final descriptions =
              Map<String, String>.from(sectionData['descriptions'] as Map? ?? {});
          final other = (sectionData['other'] as String?) ?? '';
          if (section.key == 'lids') {
            final isNormal = selected.contains('Normal');
            final lidsOptions =
                section.options.where((o) => o != 'Normal').toList();
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Normal'),
                            selected: isNormal,
                            onSelected: (value) {
                              if (!value) {
                                widget.onSelectionChanged(
                                  widget.eyeKey,
                                  section.key,
                                  <String>[],
                                );
                                return;
                              }
                              setState(() => _showLidsOptions = false);
                              widget.onSelectionChanged(
                                widget.eyeKey,
                                section.key,
                                <String>['Normal'],
                              );
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Abnormal'),
                            selected: _showLidsOptions && !isNormal,
                            onSelected: (value) {
                              setState(() => _showLidsOptions = value);
                              if (value && isNormal) {
                                widget.onSelectionChanged(
                                  widget.eyeKey,
                                  section.key,
                                  <String>[],
                                );
                              } else if (!value) {
                                widget.onSelectionChanged(
                                  widget.eyeKey,
                                  section.key,
                                  <String>[],
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      if (_showLidsOptions) ...[
                        const SizedBox(height: 8),
                        TaxonomyMultiSelectField(
                          label: 'Lids findings',
                          options: lidsOptions,
                          selected: selected.where((o) => o != 'Normal').toList(),
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
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TaxonomyMultiSelectField(
                  label: section.label,
                  options: section.options,
                  selected: selected,
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
