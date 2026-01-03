import 'package:flutter/material.dart';

import '../../../domain/constants/diagnosis_options.dart';

class Step8DiagnosisKeywords extends StatefulWidget {
  const Step8DiagnosisKeywords({
    super.key,
    required this.formKey,
    required this.diagnosisController,
    required this.diagnosisReController,
    required this.diagnosisLeController,
    required this.keywordsController,
    required this.diagnoses,
    required this.diagnosesRe,
    required this.diagnosesLe,
    required this.onDiagnosesChanged,
    required this.onDiagnosesReChanged,
    required this.onDiagnosesLeChanged,
    required this.keywords,
    required this.onKeywordsChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController diagnosisController;
  final TextEditingController diagnosisReController;
  final TextEditingController diagnosisLeController;
  final TextEditingController keywordsController;
  final List<String> diagnoses;
  final List<String> diagnosesRe;
  final List<String> diagnosesLe;
  final ValueChanged<List<String>> onDiagnosesChanged;
  final ValueChanged<List<String>> onDiagnosesReChanged;
  final ValueChanged<List<String>> onDiagnosesLeChanged;
  final List<String> keywords;
  final ValueChanged<List<String>> onKeywordsChanged;

  @override
  State<Step8DiagnosisKeywords> createState() =>
      _Step8DiagnosisKeywordsState();
}

class _Step8DiagnosisKeywordsState extends State<Step8DiagnosisKeywords> {
  final TextEditingController _searchController = TextEditingController();
  late List<String> _selectedDiagnoses;
  late List<String> _selectedDiagnosesRe;
  late List<String> _selectedDiagnosesLe;

  @override
  void initState() {
    super.initState();
    _selectedDiagnoses = _normalize(widget.diagnoses);
    _selectedDiagnosesRe = _normalize(widget.diagnosesRe);
    _selectedDiagnosesLe = _normalize(widget.diagnosesLe);
  }

  @override
  void didUpdateWidget(covariant Step8DiagnosisKeywords oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.diagnoses != widget.diagnoses) {
      _selectedDiagnoses = _normalize(widget.diagnoses);
    }
    if (oldWidget.diagnosesRe != widget.diagnosesRe) {
      _selectedDiagnosesRe = _normalize(widget.diagnosesRe);
    }
    if (oldWidget.diagnosesLe != widget.diagnosesLe) {
      _selectedDiagnosesLe = _normalize(widget.diagnosesLe);
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
        padding: const EdgeInsets.all(20),
        children: [
          // Diagnosis Section
          FormField<void>(
            validator: (_) {
              if (_selectedDiagnoses.isEmpty) return 'Required';
              return null;
            },
            builder: (field) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _openDiagnosisPicker,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.medical_information_rounded,
                                  size: 24,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Diagnosis',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedDiagnoses.isEmpty
                                          ? 'Tap to select diagnosis'
                                          : '${_selectedDiagnoses.length} diagnosis selected',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_selectedDiagnoses.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _selectedDiagnoses.map((d) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444).withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      d,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _removeDiagnosis(d),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    if (field.errorText != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          field.errorText!,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Right Eye Diagnosis
          _EyeDiagnosisSection(
            eye: 'Right Eye',
            color: const Color(0xFF10B981),
            icon: Icons.visibility_outlined,
            selectedDiagnoses: _selectedDiagnosesRe,
            onTap: () => _openEyeDiagnosisPicker('RE'),
            onRemove: _removeDiagnosisRe,
          ),
          const SizedBox(height: 20),

          // Left Eye Diagnosis
          _EyeDiagnosisSection(
            eye: 'Left Eye',
            color: const Color(0xFF3B82F6),
            icon: Icons.visibility_outlined,
            selectedDiagnoses: _selectedDiagnosesLe,
            onTap: () => _openEyeDiagnosisPicker('LE'),
            onRemove: _removeDiagnosisLe,
          ),
          const SizedBox(height: 24),
          // Keywords Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981).withOpacity(0.05),
                  const Color(0xFF34D399).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF34D399)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.label_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Keywords (max 5)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: tooMany
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.keywords.length}/5',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: widget.keywordsController,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Enter keywords (comma separated)',
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                      hintText: 'e.g., cataract, diabetes, retinal',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF10B981),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    onChanged: (value) => _parseKeywords(value),
                  ),
                ),
                if (tooMany)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.warning_rounded,
                          size: 16,
                          color: Color(0xFFEF4444),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Maximum 5 keywords allowed',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.keywords.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: widget.keywords.map((k) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF34D399)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              k,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                final updated =
                                    widget.keywords.where((e) => e != k).toList();
                                _setKeywords(updated);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
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

  void _addDiagnosisRe(String value) {
    final updated = [..._selectedDiagnosesRe, value];
    _setDiagnosesRe(updated);
    setState(() {});
  }

  void _removeDiagnosisRe(String value) {
    final updated = _selectedDiagnosesRe.where((d) => d != value).toList();
    _setDiagnosesRe(updated);
    setState(() {});
  }

  void _setDiagnosesRe(List<String> next) {
    final normalized = _normalize(next);
    _selectedDiagnosesRe = normalized;
    widget.diagnosisReController.text = normalized.join(', ');
    widget.onDiagnosesReChanged(normalized);
  }

  void _addDiagnosisLe(String value) {
    final updated = [..._selectedDiagnosesLe, value];
    _setDiagnosesLe(updated);
    setState(() {});
  }

  void _removeDiagnosisLe(String value) {
    final updated = _selectedDiagnosesLe.where((d) => d != value).toList();
    _setDiagnosesLe(updated);
    setState(() {});
  }

  void _setDiagnosesLe(List<String> next) {
    final normalized = _normalize(next);
    _selectedDiagnosesLe = normalized;
    widget.diagnosisLeController.text = normalized.join(', ');
    widget.onDiagnosesLeChanged(normalized);
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

  Future<void> _openEyeDiagnosisPicker(String eye) async {
    final options = diagnosisOptions.toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final selected = eye == 'RE'
        ? List<String>.from(_selectedDiagnosesRe)
        : List<String>.from(_selectedDiagnosesLe);
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: eye == 'RE'
                            ? const Color(0xFF10B981)
                            : const Color(0xFF3B82F6),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            eye == 'RE' ? 'Right Eye Diagnosis' : 'Left Eye Diagnosis',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Type to filter',
                          prefixIcon: Icon(Icons.search),
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
                            activeColor: eye == 'RE'
                                ? const Color(0xFF10B981)
                                : const Color(0xFF3B82F6),
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
                              if (eye == 'RE') {
                                _setDiagnosesRe(selected);
                              } else {
                                _setDiagnosesLe(selected);
                              }
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

// Eye Diagnosis Section Widget
class _EyeDiagnosisSection extends StatelessWidget {
  const _EyeDiagnosisSection({
    required this.eye,
    required this.color,
    required this.icon,
    required this.selectedDiagnoses,
    required this.onTap,
    required this.onRemove,
  });

  final String eye;
  final Color color;
  final IconData icon;
  final List<String> selectedDiagnoses;
  final VoidCallback onTap;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eye,
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedDiagnoses.isEmpty
                                ? 'Tap to select diagnosis'
                                : '${selectedDiagnoses.length} diagnosis selected',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: color,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (selectedDiagnoses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedDiagnoses.map((d) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            d,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => onRemove(d),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
