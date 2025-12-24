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
  DateTime _examDate = DateTime.now();
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
                      value: _gender,
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
                      value: _durationUnit,
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: mutation.isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B5FFF),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: mutation.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Case',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Case created successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create case: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}
