import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../logbook/data/entries_repository.dart';
import '../../logbook/domain/elog_entry.dart';
import '../../logbook/presentation/widgets/entry_card.dart';
import '../../clinical_cases/data/clinical_cases_repository.dart';
import '../../clinical_cases/data/clinical_cases_repository.dart' show ClinicalCase;
import '../../teaching/data/teaching_repository.dart';
import '../../portfolio/data/portfolio_repository.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  static const _filterClinical = 'clinical';
  static const _filterTeaching = 'teaching';
  static const _filterResearch = 'research';
  static const _filterPublications = 'publications';

  String _query = '';
  String _moduleFilter = 'all';
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery?.trim() ?? '';
    _searchController = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
              controller: _searchController,
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
                ChoiceChip(
                  label: const Text('Clinical Cases'),
                  selected: _moduleFilter == _filterClinical,
                  onSelected: (_) =>
                      setState(() => _moduleFilter = _filterClinical),
                ),
                ChoiceChip(
                  label: const Text('Teaching'),
                  selected: _moduleFilter == _filterTeaching,
                  onSelected: (_) =>
                      setState(() => _moduleFilter = _filterTeaching),
                ),
                ChoiceChip(
                  label: const Text('Research'),
                  selected: _moduleFilter == _filterResearch,
                  onSelected: (_) =>
                      setState(() => _moduleFilter = _filterResearch),
                ),
                ChoiceChip(
                  label: const Text('Publications'),
                  selected: _moduleFilter == _filterPublications,
                  onSelected: (_) =>
                      setState(() => _moduleFilter = _filterPublications),
                ),
                ...moduleTypes.map(
                  (m) => ChoiceChip(
                    label: Text('Logbook ${m.toUpperCase()}'),
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
    if (query.trim().isEmpty) {
      return const Center(child: Text('Type to search'));
    }

    final futures = moduleTypes.map((m) {
      if (moduleFilter != 'all' && m != moduleFilter) {
        return Future.value(<ElogEntry>[]);
      }
      return ref.read(entriesRepositoryProvider).listEntries(
            moduleType: m,
            search: query,
            onlyMine: false,
          );
    }).toList();

    final caseFuture = (moduleFilter == 'all' || moduleFilter == _GlobalSearchScreenState._filterClinical)
        ? ref
            .read(clinicalCasesRepositoryProvider)
            .listCases()
            .then((list) => list
                .where((c) =>
                    c.keywords.any((k) =>
                        k.toLowerCase().contains(query.toLowerCase())) ||
                    c.patientName.toLowerCase().contains(query.toLowerCase()) ||
                    c.diagnosis.toLowerCase().contains(query.toLowerCase()))
                .toList())
        : Future.value(<ClinicalCase>[]);

    final teachingFuture = (moduleFilter == 'all' || moduleFilter == _GlobalSearchScreenState._filterTeaching)
        ? ref.read(teachingRepositoryProvider).listTeaching().then(
              (list) => list
                  .where((t) =>
                      t.title.toLowerCase().contains(query.toLowerCase()) ||
                      t.keywords.any(
                          (k) => k.toLowerCase().contains(query.toLowerCase())))
                  .toList(),
            )
        : Future.value(<TeachingItem>[]);

    final researchFuture = (moduleFilter == 'all' || moduleFilter == _GlobalSearchScreenState._filterResearch)
        ? ref.read(portfolioRepositoryProvider).listResearch().then(
              (list) => list
                  .where((r) =>
                      r.title.toLowerCase().contains(query.toLowerCase()) ||
                      (r.summary ?? '')
                          .toLowerCase()
                          .contains(query.toLowerCase()) ||
                      r.keywords
                          .any((k) => k.toLowerCase().contains(query.toLowerCase())))
                  .toList(),
            )
        : Future.value(<ResearchProject>[]);

    final publicationFuture = (moduleFilter == 'all' || moduleFilter == _GlobalSearchScreenState._filterPublications)
        ? ref.read(portfolioRepositoryProvider).listPublications().then(
              (list) => list
                  .where((p) =>
                      p.title.toLowerCase().contains(query.toLowerCase()) ||
                      (p.venueOrJournal ?? '')
                          .toLowerCase()
                          .contains(query.toLowerCase()) ||
                      p.keywords.any(
                          (k) => k.toLowerCase().contains(query.toLowerCase())))
                  .toList(),
            )
        : Future.value(<PublicationItem>[]);

    return FutureBuilder(
      future: Future.wait(futures).then((logEntries) async {
        final cases = await caseFuture;
        final teaching = await teachingFuture;
        final research = await researchFuture;
        final publications = await publicationFuture;
        return {
          'log': logEntries,
          'cases': cases,
          'teaching': teaching,
          'research': research,
          'publications': publications,
        };
      }),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data as Map;
        final logLists = (data['log'] as List<List<ElogEntry>>);
        final all = logLists.expand((e) => e).toList();
        final grouped = <String, List<ElogEntry>>{};
        for (final entry in all) {
          grouped.putIfAbsent(entry.moduleType, () => []).add(entry);
        }
        final cases = data['cases'] as List<ClinicalCase>;
        final teaching = data['teaching'] as List<TeachingItem>;
        final research = data['research'] as List<ResearchProject>;
        final publications = data['publications'] as List<PublicationItem>;
        if (grouped.isEmpty &&
            cases.isEmpty &&
            teaching.isEmpty &&
            research.isEmpty &&
            publications.isEmpty) {
          return const Center(child: Text('No results'));
        }
        return ListView(
          children: [
            ...grouped.entries.map((group) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LOGBOOK ${group.key.toUpperCase()}',
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
            }),
            if (cases.isNotEmpty) ...[
              Text(
                'CLINICAL CASES',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...cases.map(
                (c) => ListTile(
                  title: Text(c.patientName),
                  subtitle: Text('${c.uidNumber} - ${c.diagnosis}'),
                  onTap: () => GoRouter.of(context).go(_caseRoute(c)),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (teaching.isNotEmpty) ...[
              Text(
                'TEACHING LIBRARY',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...teaching.map(
                (t) => ListTile(
                  title: Text(t.title),
                  subtitle: Text(t.moduleType.toUpperCase()),
                  onTap: () =>
                      GoRouter.of(context).go('/teaching/${t.id}', extra: t),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (research.isNotEmpty) ...[
              Text(
                'RESEARCH PROJECTS',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...research.map(
                (r) => ListTile(
                  title: Text(r.title),
                  subtitle: Text(r.status),
                  onTap: () => GoRouter.of(context).go('/research/${r.id}'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (publications.isNotEmpty) ...[
              Text(
                'PRESENTATIONS AND PUBLICATIONS',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...publications.map(
                (p) => ListTile(
                  title: Text(p.title),
                  subtitle: Text(p.type),
                  onTap: () => GoRouter.of(context).go('/publications/${p.id}'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

String _caseRoute(ClinicalCase c) {
  final keywords = c.keywords.map((k) => k.toLowerCase()).toList();
  if (keywords.any((k) => k.contains('retinoblastoma'))) {
    return '/cases/retinoblastoma/${c.id}';
  }
  if (keywords.any((k) => k == 'rop')) {
    return '/cases/rop/${c.id}';
  }
  if (keywords.any((k) => k == 'laser')) {
    return '/cases/laser/${c.id}';
  }
  return '/cases/${c.id}';
}
