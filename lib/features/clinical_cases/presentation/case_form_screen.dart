import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/clinical_cases_controller.dart';

const bcvaOptions = [
  '6/6',
  '6/9',
  '6/12',
  '6/18',
  '6/24',
  '6/36',
  '6/60',
  'CF',
  'PL',
  'NPL',
];

class ClinicalCaseFormScreen extends ConsumerStatefulWidget {
  const ClinicalCaseFormScreen({super.key});

  @override
  ConsumerState<ClinicalCaseFormScreen> createState() => _ClinicalCaseFormScreenState();
}

class _ClinicalCaseFormScreenState extends ConsumerState<ClinicalCaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientName = TextEditingController();
  final _uid = TextEditingController();
  final _mr = TextEditingController();
  final _chief = TextEditingController();
  final _diagnosis = TextEditingController();
  final _keywords = TextEditingController();
  final DateTime _examDate = DateTime.now();
  String _gender = 'male';
  String _durationUnit = 'days';
  int _durationValue = 1;
  int _age = 30;

  @override
  Widget build(BuildContext context) {
    final mutation = ref.watch(clinicalCaseMutationProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('New Clinical Case')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _patientName,
                decoration: const InputDecoration(labelText: 'Patient name'),
                validator: _req,
              ),
              TextFormField(
                controller: _uid,
                decoration: const InputDecoration(labelText: 'UID number'),
                validator: _req,
              ),
              TextFormField(
                controller: _mr,
                decoration: const InputDecoration(labelText: 'MR number'),
                validator: _req,
              ),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                      ],
                      onChanged: (v) => setState(() => _gender = v ?? 'male'),
                      decoration: const InputDecoration(labelText: 'Gender'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: '30',
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _age = int.tryParse(v) ?? 0,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _chief,
                decoration: const InputDecoration(labelText: 'Chief complaint'),
                validator: _req,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: '1',
                      decoration: const InputDecoration(labelText: 'Duration value'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _durationValue = int.tryParse(v) ?? 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _durationUnit,
                      items: const [
                        DropdownMenuItem(value: 'days', child: Text('Days')),
                        DropdownMenuItem(value: 'weeks', child: Text('Weeks')),
                        DropdownMenuItem(value: 'years', child: Text('Years')),
                      ],
                      onChanged: (v) => setState(() => _durationUnit = v ?? 'days'),
                      decoration: const InputDecoration(labelText: 'Duration unit'),
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _diagnosis,
                decoration: const InputDecoration(labelText: 'Diagnosis'),
                validator: _req,
              ),
              TextFormField(
                controller: _keywords,
                decoration: const InputDecoration(
                    labelText: 'Keywords (comma, max 5)'),
                validator: (v) {
                  final arr = v?.split(',').where((e) => e.trim().isNotEmpty).toList() ?? [];
                  if (arr.length > 5) return 'Max 5 keywords';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: mutation.isLoading ? null : _save,
                child: const Text('Save case'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final keywords = _keywords.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final data = {
      'date_of_examination': _examDate.toIso8601String(),
      'patient_name': _patientName.text.trim(),
      'uid_number': _uid.text.trim(),
      'mr_number': _mr.text.trim(),
      'patient_gender': _gender,
      'patient_age': _age,
      'chief_complaint': _chief.text.trim(),
      'complaint_duration_value': _durationValue,
      'complaint_duration_unit': _durationUnit,
      'systemic_history': [],
      'diagnosis': _diagnosis.text.trim(),
      'keywords': keywords,
    };
    try {
      final id =
          await ref.read(clinicalCaseMutationProvider.notifier).create(data);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/cases/$id');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }
}
