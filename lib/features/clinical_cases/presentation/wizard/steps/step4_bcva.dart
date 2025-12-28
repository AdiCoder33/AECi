import 'package:flutter/material.dart';

import '../../../data/clinical_case_constants.dart';

class Step4Bcva extends StatelessWidget {
  const Step4Bcva({
    super.key,
    required this.formKey,
    required this.bcvaRe,
    required this.bcvaLe,
    required this.onBcvaReChanged,
    required this.onBcvaLeChanged,
  });

  final GlobalKey<FormState> formKey;
  final String bcvaRe;
  final String bcvaLe;
  final ValueChanged<String> onBcvaReChanged;
  final ValueChanged<String> onBcvaLeChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _EyeField(
                  label: 'RE',
                  value: bcvaRe,
                  onChanged: onBcvaReChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _EyeField(
                  label: 'LE',
                  value: bcvaLe,
                  onChanged: onBcvaLeChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EyeField extends StatelessWidget {
  const _EyeField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value.isEmpty ? null : value,
          items: bcvaOptions
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          decoration: const InputDecoration(labelText: 'BCVA'),
          validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
          onChanged: (val) => onChanged(val ?? ''),
        ),
      ],
    );
  }
}
