import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../clinical_cases/application/clinical_cases_controller.dart';
import '../../home/application/dashboard_providers.dart';
import '../../logbook/data/entries_repository.dart';
import '../../logbook/domain/elog_entry.dart';
import '../../reviewer/data/reviewer_repository.dart';

final surgeryCountsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final repo = ref.watch(entriesRepositoryProvider);
  final entries = await repo.listEntries(moduleType: moduleRecords, onlyMine: true);
  final counts = <String, int>{};
  for (final entry in entries) {
    final payload = entry.payload;
    final surgery = (payload['surgery'] ??
            payload['learningPointOrComplication'] ??
            '')
        .toString()
        .trim();
    if (surgery.isEmpty) continue;
    counts[surgery] = (counts[surgery] ?? 0) + 1;
  }
  return counts;
});

final oscarScoresProvider =
    FutureProvider.autoDispose<List<ReviewerAssessment>>((ref) async {
  final repo = ref.watch(reviewerRepositoryProvider);
  return repo.listAssessmentsForTrainee();
});

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logbookStats = ref.watch(fellowDashboardProvider);
    final surgeryCounts = ref.watch(surgeryCountsProvider);
    final ropCases = ref.watch(clinicalCaseListByKeywordProvider('rop'));
    final retinoCases =
        ref.watch(clinicalCaseListByKeywordProvider('retinoblastoma'));
    final oscarScores = ref.watch(oscarScoresProvider);

    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primary, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Logbook Overview',
                  child: logbookStats.when(
                    data: (stats) => _OverviewCards(stats: stats),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text(
                      'Failed to load overview: $e',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _NumberedLine(
                  number: '1',
                  text: 'Total no. of surgeries',
                  trailing: surgeryCounts.when(
                    data: (counts) =>
                        _totalSurgeries(counts).toString(),
                    loading: () => '...',
                    error: (_, __) => '-',
                  ),
                ),
                const SizedBox(height: 8),
                surgeryCounts.when(
                  data: (counts) => _SurgeryBreakdown(counts: counts),
                  loading: () =>
                      const Text('Loading surgical breakdown...'),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 16),
                _NumberedLine(
                  number: '2',
                  text: 'ROP screening no.',
                  trailing: ropCases.when(
                    data: (cases) => cases.length.toString(),
                    loading: () => '...',
                    error: (_, __) => '-',
                  ),
                ),
                const SizedBox(height: 8),
                _NumberedLine(
                  number: '3',
                  text: 'Retinoblastoma screening no.',
                  trailing: retinoCases.when(
                    data: (cases) => cases.length.toString(),
                    loading: () => '...',
                    error: (_, __) => '-',
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'OSCAR scoring (case wise)',
                  child: oscarScores.when(
                    data: (scores) => _OscarGraph(scores: scores),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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

class _OverviewCards extends StatelessWidget {
  const _OverviewCards({required this.stats});

  final FellowDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            label: 'Drafts',
            value: stats.drafts,
            icon: Icons.edit_note,
            color: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStatCard(
            label: 'Submitted',
            value: stats.submitted,
            icon: Icons.upload_file,
            color: const Color(0xFF0B5FFF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStatCard(
            label: 'Approved',
            value: stats.approved,
            icon: Icons.check_circle_outline,
            color: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EAF2)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _NumberedLine extends StatelessWidget {
  const _NumberedLine({
    required this.number,
    required this.text,
    required this.trailing,
  });

  final String number;
  final String text;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number.',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Text(
          trailing,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _SurgeryBreakdown extends StatelessWidget {
  const _SurgeryBreakdown({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final breakdown = _mergeSurgeryCounts(counts);
    if (breakdown.isEmpty) {
      return const Text('No surgical records yet.');
    }
    return Column(
      children: breakdown.entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '- ${entry.key}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    entry.value.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _OscarGraph extends StatelessWidget {
  const _OscarGraph({required this.scores});

  final List<ReviewerAssessment> scores;

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) {
      return const Text('No OSCAR scores yet.');
    }
    final values = scores
        .map((s) => s.oscarTotal ?? s.score ?? 0)
        .where((v) => v > 0)
        .toList();
    if (values.isEmpty) {
      return const Text('No OSCAR scores yet.');
    }
    final maxValue = max(1, values.reduce(max));
    return Column(
      children: scores.take(5).map((score) {
        final value = score.oscarTotal ?? score.score ?? 0;
        final label = score.entityType == 'clinical_case'
            ? 'Clinical case'
            : 'Surgical video';
        final progress = value / maxValue;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                flex: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceVariant,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

int _totalSurgeries(Map<String, int> counts) {
  var total = 0;
  for (final value in counts.values) {
    total += value;
  }
  return total;
}

Map<String, int> _mergeSurgeryCounts(Map<String, int> counts) {
  const options = [
    'SOR',
    'VH',
    'RRD',
    'SFIOL',
    'MH',
    'Scleral buckle',
    'Belt buckle',
    'ERM',
    'TRD',
    'PPL+PPV+SFIOL',
    'ROP laser',
  ];
  final merged = <String, int>{};
  var other = 0;
  for (final entry in counts.entries) {
    if (options.contains(entry.key)) {
      merged[entry.key] = entry.value;
    } else {
      other += entry.value;
    }
  }
  for (final option in options) {
    merged.putIfAbsent(option, () => 0);
  }
  if (other > 0) {
    merged['Other'] = other;
  }
  return merged;
}
