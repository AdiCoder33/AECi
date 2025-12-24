import 'package:flutter/material.dart';

import '../../../data/clinical_case_constants.dart';

class Step6Anterior extends StatelessWidget {
  const Step6Anterior({
    super.key,
    required this.formKey,
    required this.anterior,
    required this.onChanged,
  });

  final GlobalKey<FormState> formKey;
  final Map<String, dynamic> anterior;
  final ValueChanged<Map<String, dynamic>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _EyeSection(
            title: 'Right Eye (RE)',
            eyeKey: 'RE',
            anterior: anterior,
            onChanged: onChanged,
          ),
          const SizedBox(height: 16),
          _EyeSection(
            title: 'Left Eye (LE)',
            eyeKey: 'LE',
            anterior: anterior,
            onChanged: onChanged,
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
  });

  final String title;
  final String eyeKey;
  final Map<String, dynamic> anterior;
  final ValueChanged<Map<String, dynamic>> onChanged;

  @override
  Widget build(BuildContext context) {
    final eye = Map<String, dynamic>.from(anterior[eyeKey] as Map? ?? {});
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            ...anteriorSegments.map((field) {
              final fieldData =
                  Map<String, dynamic>.from(eye[field] as Map? ?? {});
              final status = (fieldData['status'] as String?) ?? 'normal';
              final notes = (fieldData['notes'] as String?) ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Normal'),
                          selected: status == 'normal',
                          onSelected: (_) =>
                              _updateField(field, 'normal', notes),
                        ),
                        ChoiceChip(
                          label: const Text('Abnormal'),
                          selected: status == 'abnormal',
                          onSelected: (_) =>
                              _updateField(field, 'abnormal', notes),
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
                        onChanged: (value) =>
                            _updateField(field, status, value),
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
        ),
      ),
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
      copy[entry.key] = Map<String, dynamic>.from(entry.value as Map);
    }
    return copy;
  }
}
