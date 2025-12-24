import 'package:flutter/material.dart';

import '../../../data/clinical_case_constants.dart';

class Step2Complaints extends StatelessWidget {
  const Step2Complaints({
    super.key,
    required this.formKey,
    required this.chiefController,
    required this.durationController,
    required this.durationUnit,
    required this.onDurationUnitChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController chiefController;
  final TextEditingController durationController;
  final String durationUnit;
  final ValueChanged<String> onDurationUnitChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: chiefController,
            decoration: const InputDecoration(labelText: 'Chief Complaint'),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: durationController,
            decoration:
                const InputDecoration(labelText: 'Duration (numeric value)'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Required';
              final numValue = int.tryParse(value);
              if (numValue == null || numValue <= 0) {
                return 'Enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: complaintUnits.map((unit) {
              final selected = durationUnit == unit;
              return ChoiceChip(
                label: Text(unit[0].toUpperCase() + unit.substring(1)),
                selected: selected,
                onSelected: (_) => onDurationUnitChanged(unit),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }
}
