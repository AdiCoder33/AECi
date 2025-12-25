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
          ...fundusFields.map((field) {
            final current = fundus[field] as String? ?? '';
            final label =
                '${field[0].toUpperCase()}${field.substring(1)}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<String>(
                value: current.isEmpty ? null : current,
                items: fundusOptions
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                decoration: InputDecoration(labelText: label),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
                onChanged: (value) {
                  final next = Map<String, dynamic>.from(fundus);
                  next[field] = value ?? '';
                  onChanged(next);
                },
              ),
            );
          }),
          TextFormField(
            key: ValueKey(fundus['others'] ?? ''),
            initialValue: fundus['others'] as String? ?? '',
            decoration: const InputDecoration(
              labelText: 'Others (optional)',
            ),
            onChanged: (value) {
              final next = Map<String, dynamic>.from(fundus);
              next['others'] = value;
              onChanged(next);
            },
          ),
        ],
      ),
    );
  }
}
