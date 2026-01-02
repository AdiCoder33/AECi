import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/clinical_cases_controller.dart';

class RetinoblastomaDetailScreen extends ConsumerWidget {
  const RetinoblastomaDetailScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseAsync = ref.watch(clinicalCaseDetailProvider(caseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Retinoblastoma Screening'),
        actions: [
          caseAsync.maybeWhen(
            data: (c) => IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(
                '/cases/${c.id}/edit?type=retinoblastoma',
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: caseAsync.when(
        data: (c) {
          final anterior = c.anteriorSegment ?? const <String, dynamic>{};
          final fundus = c.fundus ?? const <String, dynamic>{};
          final rb =
              Map<String, dynamic>.from(anterior['retinoblastoma'] as Map? ?? {});

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                title: 'Patient Details',
                child: Column(
                  children: [
                    _InfoRow(label: 'Patient', value: c.patientName),
                    _InfoRow(label: 'Age', value: c.patientAge.toString()),
                    _InfoRow(label: 'UID', value: c.uidNumber),
                    _InfoRow(label: 'MRN', value: c.mrNumber),
                    _InfoRow(label: 'Gender', value: c.patientGender),
                    _InfoRow(label: 'Exam Date', value: _fmtDate(c.dateOfExamination)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Anterior Segment Remarks',
                child: Column(
                  children: [
                    _EyePairRow(
                      label: 'Remarks',
                      right: _eyeRemarks(anterior, 'RE'),
                      left: _eyeRemarks(anterior, 'LE'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Fundus Examination',
                child: Column(
                  children: [
                    _EyePairRow(
                      label: 'Media',
                      right: _selectedValue(fundus, 'RE', 'media'),
                      left: _selectedValue(fundus, 'LE', 'media'),
                    ),
                    const SizedBox(height: 8),
                    _EyePairRow(
                      label: 'Optic disc',
                      right: _selectedValue(fundus, 'RE', 'optic_disc'),
                      left: _selectedValue(fundus, 'LE', 'optic_disc'),
                    ),
                    const SizedBox(height: 8),
                    _EyePairRow(
                      label: 'Vessels',
                      right: _selectedValue(fundus, 'RE', 'vessels'),
                      left: _selectedValue(fundus, 'LE', 'vessels'),
                    ),
                    const SizedBox(height: 8),
                    _EyePairRow(
                      label: 'Background',
                      right: _selectedValue(fundus, 'RE', 'background_retina'),
                      left: _selectedValue(fundus, 'LE', 'background_retina'),
                    ),
                    const SizedBox(height: 8),
                    _EyePairRow(
                      label: 'Macula',
                      right: _selectedValue(fundus, 'RE', 'macula'),
                      left: _selectedValue(fundus, 'LE', 'macula'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Retinoblastoma Details',
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Vitreous seedings',
                      value: _boolLabel(rb['vitreous_seedings'] as bool?),
                    ),
                    _InfoRow(
                      label: 'Retinal detachment',
                      value: _boolLabel(rb['retinal_detachment'] as bool?),
                    ),
                    _InfoRow(
                      label: 'Group',
                      value: rb['group']?.toString() ?? '-',
                    ),
                    _InfoRow(
                      label: 'Regression pattern',
                      value: rb['regression_pattern']?.toString() ?? '-',
                    ),
                    _InfoRow(
                      label: 'Treatment given',
                      value: _joinList(rb['treatment_given']),
                    ),
                    if ((rb['treatment_other'] ?? '').toString().trim().isNotEmpty)
                      _InfoRow(
                        label: 'Treatment (other)',
                        value: rb['treatment_other']?.toString() ?? '-',
                      ),
                    _InfoRow(
                      label: 'No. of sittings',
                      value: rb['sittings']?.toString() ?? '-',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Diagnosis & Remarks',
                child: Column(
                  children: [
                    _InfoRow(label: 'Diagnosis', value: c.diagnosis),
                    _InfoRow(
                      label: 'Remarks',
                      value: (c.management ?? '').isEmpty ? '-' : c.management!,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

String _fmtDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _selectedValue(
  Map<String, dynamic> payload,
  String eye,
  String key,
) {
  final eyeMap = Map<String, dynamic>.from(payload[eye] as Map? ?? {});
  final section = Map<String, dynamic>.from(eyeMap[key] as Map? ?? {});
  final selected = (section['selected'] as List?)?.cast<String>() ?? const [];
  if (selected.isEmpty) return '-';
  return selected.join(', ');
}

String _eyeRemarks(Map<String, dynamic> anterior, String eye) {
  final eyeMap = Map<String, dynamic>.from(anterior[eye] as Map? ?? {});
  final remarks = (eyeMap['remarks'] as String?) ?? '';
  return remarks.trim().isEmpty ? '-' : remarks.trim();
}

String _boolLabel(bool? value) {
  if (value == null) return '-';
  return value ? 'Yes' : 'No';
}

String _joinList(dynamic value) {
  if (value is List) {
    final items = value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    if (items.isEmpty) return '-';
    return items.join(', ');
  }
  return '-';
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _EyePairRow extends StatelessWidget {
  const _EyePairRow({
    required this.label,
    required this.right,
    required this.left,
  });

  final String label;
  final String right;
  final String left;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                right,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                left,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
