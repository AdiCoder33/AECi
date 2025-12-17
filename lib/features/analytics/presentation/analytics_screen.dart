import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/analytics_repository.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  AsyncValue<AnalyticsSnapshot>? _snapshot;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final userId = auth.session?.user.id ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your metrics (last 30 days)'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      try {
                        final snap = await ref
                            .read(analyticsRepositoryProvider)
                            .compute(scope: 'user', scopeId: userId, periodDays: 30);
                        setState(() => _snapshot = AsyncValue.data(snap));
                      } catch (e, st) {
                        setState(() => _snapshot = AsyncValue.error(e, st));
                      } finally {
                        setState(() => _loading = false);
                      }
                    },
              child: Text(_loading ? 'Refreshing...' : 'Refresh analytics'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _snapshot == null
                  ? const Center(child: Text('Tap refresh to compute'))
                  : _snapshot!.when(
                      data: (snap) => _MetricsView(snapshot: snap),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsView extends StatelessWidget {
  const _MetricsView({required this.snapshot});
  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final m = snapshot.metrics;
    final byStatus = Map<String, dynamic>.from(m['byStatus'] ?? {});
    final byModule = Map<String, dynamic>.from(m['byModule'] ?? {});
    final avgQuality = m['avgQuality'] ?? 0;
    final topKeywords = (m['topKeywords'] as List?) ?? [];
    return ListView(
      children: [
        Text('Total entries: ${m['count'] ?? 0}'),
        const SizedBox(height: 8),
        const Text('By status:'),
        Wrap(
          spacing: 8,
          children: byStatus.entries
              .map((e) => Chip(label: Text('${e.key}: ${e.value}')))
              .toList(),
        ),
        const SizedBox(height: 8),
        const Text('By module:'),
        Wrap(
          spacing: 8,
          children: byModule.entries
              .map((e) => Chip(label: Text('${e.key}: ${e.value}')))
              .toList(),
        ),
        const SizedBox(height: 8),
        Text('Avg quality: ${avgQuality.toStringAsFixed(1)}'),
        const SizedBox(height: 8),
        const Text('Top keywords:'),
        Wrap(
          spacing: 8,
          children: topKeywords
              .map((e) => Chip(label: Text('${e[0]} (${e[1]})')))
              .toList()
              .cast<Widget>(),
        ),
      ],
    );
  }
}
