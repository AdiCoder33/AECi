import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/clinical_cases_controller.dart';

class LaserDetailScreen extends ConsumerWidget {
  const LaserDetailScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseAsync = ref.watch(clinicalCaseDetailProvider(caseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laser'),
        actions: [
          caseAsync.maybeWhen(
            data: (c) => IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/cases/${c.id}/edit?type=laser'),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: caseAsync.when(
        data: (c) {
          final anterior = c.anteriorSegment ?? const <String, dynamic>{};
          final laser = Map<String, dynamic>.from(anterior['laser'] as Map? ?? {});
          final bcva =
              Map<String, dynamic>.from(laser['bcva_pre'] as Map? ?? {});
          final diagnosis =
              Map<String, dynamic>.from(laser['diagnosis'] as Map? ?? {});
          final laserType =
              Map<String, dynamic>.from(laser['laser_type'] as Map? ?? {});
          final params =
              Map<String, dynamic>.from(laser['parameters'] as Map? ?? {});

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
                    _InfoRow(label: 'Age', value: c.patientAge.toString()),
                    _InfoRow(label: 'Exam Date', value: _fmtDate(c.dateOfExamination)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Laser Details',
                child: Column(
                  children: [
                    _EyePairRow(
                      label: 'BCVA (pre-laser)',
                      right: _mapEyeValue(bcva, 'RE'),
                      left: _mapEyeValue(bcva, 'LE'),
                    ),
                    const SizedBox(height: 8),
                    _EyePairRow(
                      label: 'Diagnosis',
                      right: _mapEyeValue(diagnosis, 'RE'),
                      left: _mapEyeValue(diagnosis, 'LE'),
                    ),
                    const SizedBox(height: 8),
                    _EyePairRow(
                      label: 'Laser type',
                      right: _mapEyeValue(laserType, 'RE'),
                      left: _mapEyeValue(laserType, 'LE'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Laser Parameters',
                child: Column(
                  children: [
                    _InfoRow(label: 'Power (mW)', value: _param(params, 'power')),
                    _InfoRow(label: 'Duration (ms)', value: _param(params, 'duration')),
                    _InfoRow(label: 'Interval', value: _param(params, 'interval')),
                    _InfoRow(label: 'Spot size (um)', value: _param(params, 'spot_size')),
                    _InfoRow(label: 'Pattern', value: _param(params, 'pattern')),
                    _InfoRow(label: 'Spot spacing', value: _param(params, 'spot_spacing')),
                    _InfoRow(label: 'Burn intensity', value: _param(params, 'burn_intensity')),
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

String _mapEyeValue(Map<String, dynamic> map, String eye) {
  final value = map[eye];
  if (value == null || value.toString().trim().isEmpty) return '-';
  return value.toString();
}

String _param(Map<String, dynamic> params, String key) {
  final value = params[key];
  if (value == null || value.toString().trim().isEmpty) return '-';
  return value.toString();
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
