import 'package:flutter/material.dart';

import '../../../domain/constants/diagnosis_options.dart';

class Step8DiagnosisKeywords extends StatefulWidget {
  const Step8DiagnosisKeywords({
    super.key,
    required this.formKey,
    required this.diagnosisController,
    required this.keywordsController,
    required this.diagnoses,
    required this.onDiagnosesChanged,
    required this.keywords,
    required this.onKeywordsChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController diagnosisController;
  final TextEditingController keywordsController;
  final List<String> diagnoses;
  final ValueChanged<List<String>> onDiagnosesChanged;
  final List<String> keywords;
  final ValueChanged<List<String>> onKeywordsChanged;

  @override
  State<Step8DiagnosisKeywords> createState() =>
      _Step8DiagnosisKeywordsState();
}

class _Step8DiagnosisKeywordsState extends State<Step8DiagnosisKeywords> {
  final TextEditingController _searchController = TextEditingController();
  late List<String> _selectedDiagnoses;

  @override
  void initState() {
    super.initState();
    _selectedDiagnoses = _normalize(widget.diagnoses);
  }

  @override
  void didUpdateWidget(covariant Step8DiagnosisKeywords oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.diagnoses != widget.diagnoses) {
      _selectedDiagnoses = _normalize(widget.diagnoses);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tooMany = widget.keywords.length > 5;
    return Form(
      key: widget.formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FormField<void>(
            validator: (_) {
              if (_selectedDiagnoses.isEmpty) return 'Required';
              return null;
            },
            builder: (field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: _openDiagnosisPicker,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Diagnosis',
                        errorText: field.errorText,
                      ),
                      child: Text(
                        _selectedDiagnoses.isEmpty
                            ? 'Select diagnosis'
                            : '${_selectedDiagnoses.length} selected',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedDiagnoses.map((d) {
                      return InputChip(
                        label: Text(d),
                        onDeleted: () => _removeDiagnosis(d),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.keywordsController,
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
            children: widget.keywords.map((k) {
              return InputChip(
                label: Text(k),
                onDeleted: () {
                  final updated =
                      widget.keywords.where((e) => e != k).toList();
                  _setKeywords(updated);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _addDiagnosis(String value) {
    final updated = [..._selectedDiagnoses, value];
    _setDiagnoses(updated);
    setState(() {});
  }

  void _removeDiagnosis(String value) {
    final updated = _selectedDiagnoses.where((d) => d != value).toList();
    _setDiagnoses(updated);
    setState(() {});
  }

  void _setDiagnoses(List<String> next) {
    final normalized = _normalize(next);
    _selectedDiagnoses = normalized;
    widget.diagnosisController.text = normalized.join(', ');
    widget.onDiagnosesChanged(normalized);
  }

  List<String> _normalize(List<String> list) {
    final unique = <String>[];
    for (final item in list) {
      final cleaned = item.trim();
      if (cleaned.isEmpty) continue;
      final exists = unique.any(
        (e) => e.toLowerCase() == cleaned.toLowerCase(),
      );
      if (!exists) unique.add(cleaned);
    }
    return unique;
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
    widget.onKeywordsChanged(unique);
  }

  void _setKeywords(List<String> next) {
    widget.keywordsController.text = next.join(', ');
    widget.onKeywordsChanged(next);
  }

  Future<void> _openDiagnosisPicker() async {
    final options = diagnosisOptions.toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final selected = List<String>.from(_selectedDiagnoses);
    _searchController.clear();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = _searchController.text.trim().toLowerCase();
            final filtered = query.isEmpty
                ? options
                : options
                    .where((option) =>
                        option.toLowerCase().startsWith(query))
                    .toList();
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Type to filter',
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final option = filtered[index];
                          final isChecked = selected.any(
                            (d) => d.toLowerCase() == option.toLowerCase(),
                          );
                          return CheckboxListTile(
                            value: isChecked,
                            title: Text(option),
                            onChanged: (value) {
                              if (value == true) {
                                selected.add(option);
                              } else {
                                selected.removeWhere(
                                  (d) =>
                                      d.toLowerCase() ==
                                      option.toLowerCase(),
                                );
                              }
                              setModalState(() {});
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              selected.clear();
                              setModalState(() {});
                            },
                            child: const Text('Clear'),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () {
                              _setDiagnoses(selected);
                              Navigator.of(context).pop();
                            },
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
