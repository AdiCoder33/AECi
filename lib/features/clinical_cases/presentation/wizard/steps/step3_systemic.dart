import 'package:flutter/material.dart';

import '../../../data/clinical_case_constants.dart';

class Step3Systemic extends StatelessWidget {
  const Step3Systemic({
    super.key,
    required this.selected,
    required this.otherController,
    required this.onSelectionChanged,
  });

  final List<String> selected;
  final TextEditingController otherController;
  final ValueChanged<List<String>> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final hasNil = selected.contains('Nil');
    final hasOthers = selected.contains('Others');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Select systemic history',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: systemicOptions.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              selected: isSelected,
              label: Text(option),
              onSelected: (value) {
                final next = List<String>.from(selected);
                if (option == 'Nil') {
                  if (value) {
                    next
                      ..clear()
                      ..add('Nil');
                  } else {
                    next.remove('Nil');
                  }
                } else {
                  next.remove('Nil');
                  if (value) {
                    next.add(option);
                  } else {
                    next.remove(option);
                  }
                }
                onSelectionChanged(next);
              },
            );
          }).toList(),
        ),
        if (hasOthers) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: otherController,
            decoration: const InputDecoration(
              labelText: 'Other systemic history',
            ),
            validator: (value) {
              if (!hasOthers) return null;
              if (value == null || value.trim().isEmpty) {
                return 'Please specify';
              }
              return null;
            },
          ),
        ],
        if (hasNil) ...[
          const SizedBox(height: 8),
          const Text(
            'Nil selected. Other options are cleared.',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ],
    );
  }
}
