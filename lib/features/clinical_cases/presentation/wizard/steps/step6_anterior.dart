import 'package:flutter/material.dart';

import '../../../data/clinical_case_constants.dart';
import '../../../domain/constants/anterior_lids_options.dart';
import '../../widgets/multi_select_sheet_field.dart';

class Step6Anterior extends StatelessWidget {
  const Step6Anterior({
    super.key,
    required this.formKey,
    required this.anterior,
    required this.onChanged,
    required this.onLidsFindingsChanged,
    required this.onLidsOtherNotesChanged,
  });

  final GlobalKey<FormState> formKey;
  final Map<String, dynamic> anterior;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final void Function(String eye, List<String> findings) onLidsFindingsChanged;
  final void Function(String eye, String notes) onLidsOtherNotesChanged;

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
                      onChanged: onChanged,
                      onLidsFindingsChanged: onLidsFindingsChanged,
                      onLidsOtherNotesChanged: onLidsOtherNotesChanged,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _EyeSection(
                      title: 'LE',
                      eyeKey: 'LE',
                      anterior: anterior,
                      onChanged: onChanged,
                      onLidsFindingsChanged: onLidsFindingsChanged,
                      onLidsOtherNotesChanged: onLidsOtherNotesChanged,
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

class _EyeSection extends StatelessWidget {
  const _EyeSection({
    required this.title,
    required this.eyeKey,
    required this.anterior,
    required this.onChanged,
    required this.onLidsFindingsChanged,
    required this.onLidsOtherNotesChanged,
  });

  final String title;
  final String eyeKey;
  final Map<String, dynamic> anterior;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final void Function(String eye, List<String> findings) onLidsFindingsChanged;
  final void Function(String eye, String notes) onLidsOtherNotesChanged;

  @override
  Widget build(BuildContext context) {
    final eye = Map<String, dynamic>.from(anterior[eyeKey] as Map? ?? {});
    final lidsFindings =
        (eye['lids_findings'] as List?)?.cast<String>() ?? <String>[];
    final lidsOtherNotes = (eye['lids_other_notes'] as String?) ?? '';
    final hasOther = lidsFindings.contains('Other');
    final lidsStatus = _lidsStatus(lidsFindings);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        MultiSelectSheetField(
          label: 'Lids',
          options: anteriorLidsOptions,
          selected: lidsFindings,
          onChanged: (next) {
            final normalized = _normalizeLids(next);
            onLidsFindingsChanged(eyeKey, normalized);
          },
        ),
        const SizedBox(height: 6),
        Text(
          'Status: $lidsStatus',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: lidsStatus == 'Abnormal'
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        if (hasOther) ...[
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('$eyeKey-lids-other-$lidsOtherNotes'),
            initialValue: lidsOtherNotes,
            decoration: const InputDecoration(
              labelText: 'Other notes',
            ),
            onChanged: (value) => onLidsOtherNotesChanged(eyeKey, value),
            validator: (value) {
              if (!hasOther) return null;
              if (value == null || value.trim().length < 3) {
                return 'Please enter at least 3 characters';
              }
              return null;
            },
          ),
        ],
        const SizedBox(height: 16),
        ...anteriorSegments.map((field) {
          final fieldData = Map<String, dynamic>.from(eye[field] as Map? ?? {});
          final status = (fieldData['status'] as String?) ?? 'normal';
          final notes = (fieldData['notes'] as String?) ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Normal'),
                      selected: status == 'normal',
                      onSelected: (_) => _updateField(field, 'normal', notes),
                    ),
                    ChoiceChip(
                      label: const Text('Abnormal'),
                      selected: status == 'abnormal',
                      onSelected: (_) => _updateField(field, 'abnormal', notes),
                    ),
                  ],
                ),
                if (status == 'abnormal') ...[
                  const SizedBox(height: 6),
                  TextFormField(
                    key: ValueKey('$eyeKey-$field-$notes'),
                    initialValue: notes,
                    decoration: const InputDecoration(
                      labelText: 'Notes (required)',
                    ),
                    onChanged: (value) => _updateField(field, status, value),
                    validator: (value) {
                      if (status == 'abnormal' &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Notes required';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  void _updateField(String field, String status, String notes) {
    final next = _deepCopy(anterior);
    final eye = Map<String, dynamic>.from(next[eyeKey] as Map? ?? {});
    eye[field] = {'status': status, 'notes': notes};
    next[eyeKey] = eye;
    onChanged(next);
  }

  Map<String, dynamic> _deepCopy(Map<String, dynamic> source) {
    final copy = <String, dynamic>{};
    for (final entry in source.entries) {
      if (entry.value is Map) {
        copy[entry.key] = Map<String, dynamic>.from(entry.value as Map);
      } else {
        copy[entry.key] = entry.value;
      }
    }
    return copy;
  }

  List<String> _normalizeLids(List<String> next) {
    final normalized = next.toList();
    if (normalized.contains('Normal') && normalized.length > 1) {
      return ['Normal'];
    }
    if (!normalized.contains('Normal')) {
      return normalized;
    }
    return normalized;
  }

  String _lidsStatus(List<String> findings) {
    if (findings.isEmpty) return 'Required';
    if (findings.contains('Normal')) return 'Normal';
    return 'Abnormal';
  }
}
