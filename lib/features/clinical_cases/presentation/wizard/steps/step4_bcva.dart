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
          DropdownButtonFormField<String>(
            value: bcvaRe.isEmpty ? null : bcvaRe,
            items: bcvaOptions
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            decoration: const InputDecoration(labelText: 'BCVA - Right Eye'),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Required' : null,
            onChanged: (value) => onBcvaReChanged(value ?? ''),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: bcvaLe.isEmpty ? null : bcvaLe,
            items: bcvaOptions
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            decoration: const InputDecoration(labelText: 'BCVA - Left Eye'),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Required' : null,
            onChanged: (value) => onBcvaLeChanged(value ?? ''),
          ),
        ],
      ),
    );
  }
}
