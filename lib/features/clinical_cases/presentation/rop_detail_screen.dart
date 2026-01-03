import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/clinical_cases_controller.dart';

class RopScreeningDetailScreen extends ConsumerWidget {
  const RopScreeningDetailScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseAsync = ref.watch(clinicalCaseDetailProvider(caseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('ROP Screening'),
        actions: [
          caseAsync.maybeWhen(
            data: (c) => IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  context.push('/cases/${c.id}/edit?type=rop'),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: caseAsync.when(
        data: (c) {
          final anterior = c.anteriorSegment ?? const <String, dynamic>{};
          final fundus = c.fundus ?? const <String, dynamic>{};
          final ropMeta =
              Map<String, dynamic>.from(fundus['rop_meta'] as Map? ?? {});
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                title: 'Patient Details',
                child: Column(
                  children: [
                    _InfoRow(label: 'Patient', value: c.patientName),
                    _InfoRow(label: 'UID', value: c.uidNumber),
                    _InfoRow(label: 'MRN', value: c.mrNumber),
                    _InfoRow(label: 'Gender', value: c.patientGender),
                    _InfoRow(label: 'Exam Date', value: _fmtDate(c.dateOfExamination)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Anterior Segment',
                child: Column(
                  children: [
                    _EyePairRow(
                      label: 'Pupil',
                      right: _selectedValue(anterior, 'RE', 'pupil'),
                      left: _selectedValue(anterior, 'LE', 'pupil'),
                    ),
                    const SizedBox(height: 8),
                    _EyePairRow(
                      label: 'Lens',
                      right: _selectedValue(anterior, 'RE', 'lens'),
                      left: _selectedValue(anterior, 'LE', 'lens'),
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
                title: 'ROP Assessment',
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Gestational age',
                      value: ropMeta['gestational_age']?.toString() ?? '-',
                    ),
                    _InfoRow(
                      label: 'Post conceptional age',
                      value: ropMeta['post_conceptional_age']?.toString() ?? '-',
                    ),
                    _InfoRow(
                      label: 'Birth weight',
                      value: ropMeta['birth_weight'] != null 
                          ? '${ropMeta['birth_weight']} grams'
                          : '-',
                    ),
                    const SizedBox(height: 8),
                    _EyePairRow(
                      label: 'Zone',
                      right: _eyeMapValue(ropMeta['zone'], 'RE'),
                      left: _eyeMapValue(ropMeta['zone'], 'LE'),
                    ),
                    const SizedBox(height: 8),
                    _EyePairRow(
                      label: 'Stage',
                      right: _eyeMapValue(ropMeta['stage'], 'RE'),
                      left: _eyeMapValue(ropMeta['stage'], 'LE'),
                    ),
                    const SizedBox(height: 8),
                    _EyePairRow(
                      label: 'Plus disease',
                      right: _boolLabel(_eyeMapBool(ropMeta['plus_disease'], 'RE')),
                      left: _boolLabel(_eyeMapBool(ropMeta['plus_disease'], 'LE')),
                    ),
                    const SizedBox(height: 8),
                    _EyePairRow(
                      label: 'A-ROP',
                      right: _boolLabel(_eyeMapBool(ropMeta['agrop'], 'RE')),
                      left: _boolLabel(_eyeMapBool(ropMeta['agrop'], 'LE')),
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

String _eyeMapValue(dynamic data, String eye) {
  if (data is Map) {
    final value = data[eye];
    if (value == null || value.toString().trim().isEmpty) return '-';
    return value.toString();
  }
  return '-';
}

bool? _eyeMapBool(dynamic data, String eye) {
  if (data is Map) {
    return data[eye] as bool?;
  }
  return null;
}

String _boolLabel(bool? value) {
  if (value == null) return '-';
  return value ? 'Yes' : 'No';
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
