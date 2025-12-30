import 'package:flutter/material.dart';

import '../../../domain/constants/fundus_options.dart';
import '../../widgets/taxonomy_multi_select_field.dart';

class Step7Fundus extends StatelessWidget {
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
  ) onDescriptionChanged;
  final void Function(String eye, String sectionKey, String other) onOtherChanged;
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
                    child: _EyeFundus(
                      label: 'RE',
                      eyeKey: 'RE',
                      fundus: fundus,
                      onSelectionChanged: onSelectionChanged,
                      onDescriptionChanged: onDescriptionChanged,
                      onOtherChanged: onOtherChanged,
                      onRemarksChanged: onRemarksChanged,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _EyeFundus(
                      label: 'LE',
                      eyeKey: 'LE',
                      fundus: fundus,
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
  ) onDescriptionChanged;
  final void Function(String eye, String sectionKey, String other) onOtherChanged;
  final void Function(String eye, String remarks) onRemarksChanged;

  @override
  Widget build(BuildContext context) {
    final eye = Map<String, dynamic>.from(fundus[eyeKey] as Map? ?? {});
    final remarks = (eye['remarks'] as String?) ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        ...fundusSections.map((section) {
          final sectionData =
              Map<String, dynamic>.from(eye[section.key] as Map? ?? {});
          final selected =
              (sectionData['selected'] as List?)?.cast<String>() ?? <String>[];
          final descriptions =
              Map<String, String>.from(sectionData['descriptions'] as Map? ?? {});
          final other = (sectionData['other'] as String?) ?? '';
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
                      onSelectionChanged(eyeKey, section.key, next),
                  onDescriptionChanged: (option, description) =>
                      onDescriptionChanged(
                        eyeKey,
                        section.key,
                        option,
                        description,
                      ),
                  onOtherChanged: (value) =>
                      onOtherChanged(eyeKey, section.key, value),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        TextFormField(
          key: ValueKey('$eyeKey-fundus-remarks-$remarks'),
          initialValue: remarks,
          decoration: const InputDecoration(
            labelText: 'Remarks (optional)',
          ),
          maxLines: 3,
          onChanged: (value) => onRemarksChanged(eyeKey, value),
        ),
      ],
    );
  }
}
