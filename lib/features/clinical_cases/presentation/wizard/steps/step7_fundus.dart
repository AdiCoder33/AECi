import 'package:flutter/material.dart';

import '../../../data/clinical_case_constants.dart';

class Step7Fundus extends StatelessWidget {
  const Step7Fundus({
    super.key,
    required this.formKey,
    required this.fundus,
    required this.onChanged,
  });

  final GlobalKey<FormState> formKey;
  final Map<String, dynamic> fundus;
  final ValueChanged<Map<String, dynamic>> onChanged;

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
                      onChanged: onChanged,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _EyeFundus(
                      label: 'LE',
                      eyeKey: 'LE',
                      fundus: fundus,
                      onChanged: onChanged,
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
    required this.onChanged,
  });

  final String label;
  final String eyeKey;
  final Map<String, dynamic> fundus;
  final ValueChanged<Map<String, dynamic>> onChanged;

  @override
  Widget build(BuildContext context) {
    final eye = Map<String, dynamic>.from(fundus[eyeKey] as Map? ?? {});
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
        ...fundusFields.map((field) {
          final current = eye[field] as String? ?? '';
          final labelText = '${field[0].toUpperCase()}${field.substring(1)}';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              value: current.isEmpty ? null : current,
              items: fundusOptions
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              decoration: InputDecoration(labelText: labelText),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Required' : null,
              onChanged: (value) {
                final next = _copyFundus(fundus);
                final nextEye = Map<String, dynamic>.from(next[eyeKey] as Map);
                nextEye[field] = value ?? '';
                next[eyeKey] = nextEye;
                onChanged(next);
              },
            ),
          );
        }),
        TextFormField(
          key: ValueKey('${eyeKey}_fundus_${eye['others'] ?? ''}'),
          initialValue: eye['others'] as String? ?? '',
          decoration: const InputDecoration(
            labelText: 'Others (optional)',
          ),
          onChanged: (value) {
            final next = _copyFundus(fundus);
            final nextEye = Map<String, dynamic>.from(next[eyeKey] as Map);
            nextEye['others'] = value;
            next[eyeKey] = nextEye;
            onChanged(next);
          },
        ),
      ],
    );
  }

  Map<String, dynamic> _copyFundus(Map<String, dynamic> source) {
    final copy = <String, dynamic>{};
    for (final entry in source.entries) {
      if (entry.value is Map) {
        copy[entry.key] = Map<String, dynamic>.from(entry.value as Map);
      } else {
        copy[entry.key] = entry.value;
      }
    }
    if (!copy.containsKey('RE')) copy['RE'] = {};
    if (!copy.containsKey('LE')) copy['LE'] = {};
    return copy;
  }
}
