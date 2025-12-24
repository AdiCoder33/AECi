import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../logbook/data/entries_repository.dart';
import '../../logbook/domain/elog_entry.dart';
import '../../logbook/presentation/widgets/entry_card.dart';
import '../../clinical_cases/data/clinical_cases_repository.dart';
import '../../clinical_cases/data/clinical_cases_repository.dart' show ClinicalCase;

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  String _query = '';
  String _moduleFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('Global Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search across all modules',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _moduleFilter == 'all',
                  onSelected: (_) => setState(() => _moduleFilter = 'all'),
                ),
                ...moduleTypes.map(
                  (m) => ChoiceChip(
                    label: Text(m.toUpperCase()),
                    selected: _moduleFilter == m,
                    onSelected: (_) => setState(() => _moduleFilter = m),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _SearchResults(query: _query, moduleFilter: _moduleFilter),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query, required this.moduleFilter});

  final String query;
  final String moduleFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final futures = moduleTypes.map((m) {
      if (moduleFilter != 'all' && m != moduleFilter) {
        return Future.value(<ElogEntry>[]);
      }
      return ref
          .read(entriesRepositoryProvider)
          .listEntries(
            moduleType: m,
            search: query.isEmpty ? null : query,
            onlyMine: false,
          );
    }).toList();

    final caseFuture = ref
        .read(clinicalCasesRepositoryProvider)
        .listCases()
        .then((list) => list
            .where((c) =>
                query.isEmpty ||
                c.keywords.any((k) => k.toLowerCase().contains(query.toLowerCase())) ||
                c.patientName.toLowerCase().contains(query.toLowerCase()))
            .toList());

    return FutureBuilder(
      future: Future.wait(futures).then((logEntries) async {
        final cases = await caseFuture;
        return {'log': logEntries, 'cases': cases};
      }),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data as Map;
        final logLists = (data['log'] as List<List<ElogEntry>>);
        final all = logLists.expand((e) => e).toList();
        if (all.isEmpty) {
          return const Center(child: Text('No results'));
        }
        final grouped = <String, List<ElogEntry>>{};
        for (final entry in all) {
          grouped.putIfAbsent(entry.moduleType, () => []).add(entry);
        }
        final cases = data['cases'] as List<ClinicalCase>;
        return ListView(
          children: grouped.entries.map((group) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.key.toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...group.value.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: EntryCard(
                      entry: entry,
                      onTap: () =>
                          GoRouter.of(context).go('/logbook/${entry.id}'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            );
          }).toList()
            ..add(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CLINICAL CASES'),
                  const SizedBox(height: 8),
                  ...cases.map(
                    (c) => ListTile(
                      title: Text(c.patientName),
                      subtitle: Text('${c.uidNumber} • ${c.diagnosis}'),
                      onTap: () =>
                          GoRouter.of(context).go('/cases/${c.id}'),
                    ),
                  ),
                ],
              ),
            ),
        );
      },
    );
  }
}
