import 'package:flutter/material.dart';

import '../../../domain/constants/fundus_options.dart';
import '../../widgets/taxonomy_multi_select_field.dart';

class Step7Fundus extends StatefulWidget {
  const Step7Fundus({
    super.key,
    required this.formKey,
    required this.fundus,
    required this.onSelectionChanged,
    required this.onDescriptionChanged,
    required this.onOtherChanged,
    required this.onRemarksChanged,
  });

  final GlobalKey<FormState> formKey;
  final Map<String, dynamic> fundus;
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
  State<Step7Fundus> createState() => _Step7FundusState();
}

class _Step7FundusState extends State<Step7Fundus> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          // Set All Normal Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
              Expanded(child: _buildRightEyeCard()),
              const SizedBox(width: 8),
              Expanded(child: _buildLeftEyeCard()),
            ],
          ),
        ],
      ),
    );
  }

  void _setAllNormal() {
    // Map of section keys to their normal values
    final normalValues = {
      'media': ['Clear'],
      'optic_disc': ['Normal'],
      'vessels': ['Normal'],
      'background_retina': ['Normal'],
      'macula': ['Present'],
    };

    // Set all fundus sections to their normal values for both eyes
    for (final section in fundusSections) {
      final normalValue = normalValues[section.key] ?? ['Normal'];
      widget.onSelectionChanged('RE', section.key, normalValue);
      widget.onSelectionChanged('LE', section.key, normalValue);
    }
  }

  Widget _buildRightEyeCard() {
    return Container(
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
                colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.visibility, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Right Eye Fundus',
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
            child: _EyeFundus(
              label: 'RE',
              eyeKey: 'RE',
              fundus: widget.fundus,
              onSelectionChanged: widget.onSelectionChanged,
              onDescriptionChanged: widget.onDescriptionChanged,
              onOtherChanged: widget.onOtherChanged,
              onRemarksChanged: widget.onRemarksChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftEyeCard() {
    return Container(
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
                colors: [Color(0xFF10B981), Color(0xFF34D399)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.visibility, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Left Eye Fundus',
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
            child: _EyeFundus(
              label: 'LE',
              eyeKey: 'LE',
              fundus: widget.fundus,
              onSelectionChanged: widget.onSelectionChanged,
              onDescriptionChanged: widget.onDescriptionChanged,
              onOtherChanged: widget.onOtherChanged,
              onRemarksChanged: widget.onRemarksChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _EyeFundus extends StatelessWidget {
  const _EyeFundus({
    required this.label,
    required this.eyeKey,
    required this.fundus,
    required this.onSelectionChanged,
    required this.onDescriptionChanged,
    required this.onOtherChanged,
    required this.onRemarksChanged,
  });

  final String label;
  final String eyeKey;
  final Map<String, dynamic> fundus;
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
    final eye = Map<String, dynamic>.from(fundus[eyeKey] as Map? ?? {});
    final remarks = (eye['remarks'] as String?) ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...fundusSections.map((section) {
          final sectionData = Map<String, dynamic>.from(
            eye[section.key] as Map? ?? {},
          );
          final selected =
              (sectionData['selected'] as List?)?.cast<String>() ?? <String>[];
          final descriptions = Map<String, String>.from(
            sectionData['descriptions'] as Map? ?? {},
          );
          final other = (sectionData['other'] as String?) ?? '';
          return _FundusSectionCard(
            eyeKey: eyeKey,
            section: section,
            selected: selected,
            descriptions: descriptions,
            other: other,
            onSelectionChanged: onSelectionChanged,
            onDescriptionChanged: onDescriptionChanged,
            onOtherChanged: onOtherChanged,
          );
        }),
        const SizedBox(height: 8),
        TextFormField(
          // Use a stable key per eye so typing doesn't rebuild the field.
          key: ValueKey('$eyeKey-fundus-remarks'),
          initialValue: remarks,
          decoration: const InputDecoration(labelText: 'Remarks (optional)'),
          maxLines: 3,
          onChanged: (value) => onRemarksChanged(eyeKey, value),
        ),
      ],
    );
  }
}

class _FundusSectionCard extends StatefulWidget {
  const _FundusSectionCard({
    required this.eyeKey,
    required this.section,
    required this.selected,
    required this.descriptions,
    required this.other,
    required this.onSelectionChanged,
    required this.onDescriptionChanged,
    required this.onOtherChanged,
  });

  final String eyeKey;
  final FundusSection section;
  final List<String> selected;
  final Map<String, String> descriptions;
  final String other;
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

  @override
  State<_FundusSectionCard> createState() => _FundusSectionCardState();
}

class _FundusSectionCardState extends State<_FundusSectionCard> {
  bool _expanded = false;

  String _normalOption() {
    const normalMap = {
      'media': 'Clear',
      'optic_disc': 'Normal',
      'vessels': 'Normal',
      'background_retina': 'Normal',
      'macula': 'Present',
    };
    final mapped = normalMap[widget.section.key];
    if (mapped != null && widget.section.options.contains(mapped)) {
      return mapped;
    }
    if (widget.section.options.contains('Normal')) return 'Normal';
    return widget.section.options.isNotEmpty
        ? widget.section.options.first
        : 'Normal';
  }

  bool _showOptions(String normalOption) {
    if (widget.selected.contains(normalOption)) return false;
    if (widget.selected.isNotEmpty) return true;
    return _expanded;
  }

  @override
  Widget build(BuildContext context) {
    final normalOption = _normalOption();
    final showOptions = _showOptions(normalOption);
    final filteredOptions = widget.section.options
        .where((o) => o != normalOption)
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
                widget.section.label,
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
                        widget.selected.contains(normalOption) && !showOptions,
                    onSelected: (value) {
                      if (value) {
                        setState(() => _expanded = false);
                        widget.onSelectionChanged(
                          widget.eyeKey,
                          widget.section.key,
                          <String>[normalOption],
                        );
                      } else {
                        setState(() => _expanded = true);
                        widget.onSelectionChanged(
                          widget.eyeKey,
                          widget.section.key,
                          <String>[],
                        );
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Abnormal'),
                    selected: showOptions,
                    onSelected: (value) {
                      setState(() => _expanded = value);
                      if (value && widget.selected.contains(normalOption)) {
                        widget.onSelectionChanged(
                          widget.eyeKey,
                          widget.section.key,
                          <String>[],
                        );
                      } else if (!value) {
                        widget.onSelectionChanged(
                          widget.eyeKey,
                          widget.section.key,
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
                  label: '${widget.section.label} findings',
                  options: filteredOptions,
                  selected: widget.selected
                      .where((o) => o != normalOption)
                      .toList(),
                  descriptions: widget.descriptions,
                  otherValue: widget.other,
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
                    widget.section.key,
                    next,
                  ),
                  onDescriptionChanged: (option, description) =>
                      widget.onDescriptionChanged(
                        widget.eyeKey,
                        widget.section.key,
                        option,
                        description,
                      ),
                  onOtherChanged: (value) => widget.onOtherChanged(
                    widget.eyeKey,
                    widget.section.key,
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
}
