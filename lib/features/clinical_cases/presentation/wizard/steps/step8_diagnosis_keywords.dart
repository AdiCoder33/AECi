import 'package:flutter/material.dart';

class Step8DiagnosisKeywords extends StatelessWidget {
  const Step8DiagnosisKeywords({
    super.key,
    required this.formKey,
    required this.diagnosisController,
    required this.keywordsController,
    required this.keywords,
    required this.onKeywordsChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController diagnosisController;
  final TextEditingController keywordsController;
  final List<String> keywords;
  final ValueChanged<List<String>> onKeywordsChanged;

  @override
  Widget build(BuildContext context) {
    final tooMany = keywords.length > 5;
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: diagnosisController,
            decoration: const InputDecoration(labelText: 'Diagnosis'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Required';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: keywordsController,
            decoration: const InputDecoration(
              labelText: 'Keywords (comma separated, max 5)',
            ),
            onChanged: (value) => _parseKeywords(value),
          ),
          if (tooMany)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Maximum 5 keywords allowed',
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: keywords.map((k) {
              return InputChip(
                label: Text(k),
                onDeleted: () {
                  final updated = keywords.where((e) => e != k).toList();
                  _setKeywords(updated);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _parseKeywords(String raw) {
    final parts = raw.split(',');
    final unique = <String>[];
    for (final part in parts) {
      final cleaned = part.trim();
      if (cleaned.isEmpty) continue;
      final exists = unique.any(
        (e) => e.toLowerCase() == cleaned.toLowerCase(),
      );
      if (!exists) unique.add(cleaned);
    }
    onKeywordsChanged(unique);
  }

  void _setKeywords(List<String> next) {
    keywordsController.text = next.join(', ');
    onKeywordsChanged(next);
  }
}
