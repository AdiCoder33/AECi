import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../clinical_cases/application/clinical_cases_controller.dart';
import '../../clinical_cases/data/clinical_cases_repository.dart';
import '../../portfolio/application/portfolio_controller.dart';
import '../../review/application/review_controller.dart';
import '../application/logbook_providers.dart';
import '../domain/elog_entry.dart';
import '../domain/logbook_sections.dart';
import 'widgets/entry_card.dart';

class LogbookScreen extends ConsumerStatefulWidget {
  const LogbookScreen({super.key});

  @override
  ConsumerState<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends ConsumerState<LogbookScreen> {
  @override
  Widget build(BuildContext context) {
    final section = ref.watch(logbookSectionProvider);
    final module = ref.watch(moduleSelectionProvider);
    final isEntrySection = logbookEntrySections.contains(section);
    final isCaseSection = logbookCaseSections.contains(section);
    final isPublications = section == logbookSectionPublications;
    final isReviews = section == logbookSectionReviews;
    final entries = isEntrySection ? ref.watch(entriesListProvider) : null;
    final AsyncValue<List<ClinicalCase>>? cases = isCaseSection
        ? (section == logbookSectionRetinoblastoma
            ? ref.watch(clinicalCaseListByKeywordProvider('retinoblastoma'))
            : section == logbookSectionRop
                ? ref.watch(clinicalCaseListByKeywordProvider('rop'))
                : ref.watch(clinicalCaseListProvider))
        : null;
    final publications =
        isPublications ? ref.watch(publicationListProvider) : null;
    final reviews = isReviews ? ref.watch(reviewControllerProvider) : null;
    final showMine = ref.watch(showMineProvider);
    final showDrafts = ref.watch(showDraftsProvider);

    ref.listen<String>(logbookSectionProvider, (previous, next) {
      final nextSection = logbookSections.firstWhere((s) => s.key == next);
      final mappedModule = nextSection.moduleType;
      if (mappedModule != null &&
          ref.read(moduleSelectionProvider) != mappedModule) {
        ref.read(moduleSelectionProvider.notifier).state = mappedModule;
      }
      if (next == logbookSectionReviews) {
        ref.read(reviewControllerProvider.notifier).loadQueue();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Logbook',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF64748B)),
            onPressed: () => context.push('/search'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          switch (section) {
            case logbookSectionOpdCases:
              context.push('/cases/new');
              return;
            case logbookSectionRop:
              context.push('/cases/new?type=rop');
              return;
            case logbookSectionRetinoblastoma:
              context.push('/cases/new?type=retinoblastoma');
              return;
            case logbookSectionAtlas:
            case logbookSectionSurgicalRecord:
            case logbookSectionLearning:
              context.pushNamed('logbookNew', extra: module);
              return;
            case logbookSectionPublications:
              context.pushNamed('pubNew');
              return;
            case logbookSectionReviews:
              context.push('/review-queue');
              return;
          }
        },
        backgroundColor: const Color(0xFF0B5FFF),
        elevation: 3,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Entry',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionSelector(
                  selected: section,
                  onChanged: (value) =>
                      ref.read(logbookSectionProvider.notifier).state = value,
                ),
                if (isEntrySection) ...[
                  const SizedBox(height: 16),
                  _SearchBar(
                    onChanged: (value) =>
                        ref.read(searchQueryProvider.notifier).state = value,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: 'My Entries',
                        selected: showMine,
                        onSelected: (v) =>
                            ref.read(showMineProvider.notifier).state = v,
                      ),
                      _FilterChip(
                        label: 'Drafts',
                        selected: showDrafts,
                        onSelected: (v) =>
                            ref.read(showDraftsProvider.notifier).state = v,
                      ),
                      _FilterChip(
                        label: 'Browse All',
                        selected: !showMine && !showDrafts,
                        onSelected: (v) {
                          if (v) {
                            ref.read(showMineProvider.notifier).state = false;
                            ref.read(showDraftsProvider.notifier).state = false;
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: _SectionBody(
              isEntrySection: isEntrySection,
              isCaseSection: isCaseSection,
              isPublications: isPublications,
              isReviews: isReviews,
              entries: entries,
              cases: cases,
              publications: publications,
              reviews: reviews,
              section: section,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionSelector extends StatelessWidget {
  const _SectionSelector({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: logbookSections
            .map(
              (m) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _ModuleChip(
                  label: m.label,
                  selected: selected == m.key,
                  onTap: () => onChanged(m.key),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ModuleChip extends StatelessWidget {
  const _ModuleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0B5FFF) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF1E5F8C) : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: Colors.grey[100],
      selectedColor: const Color(0xFF0B5FFF).withOpacity(0.1),
      checkmarkColor: const Color(0xFF0B5FFF),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF0B5FFF) : const Color(0xFF64748B),
        fontSize: 13,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: selected ? const Color(0xFF0B5FFF) : Colors.grey[300]!,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF94A3B8),
            size: 22,
          ),
          hintText: 'Search by patient, MRN or keyword...',
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 14,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({
    required this.isEntrySection,
    required this.isCaseSection,
    required this.isPublications,
    required this.isReviews,
    required this.entries,
    required this.cases,
    required this.publications,
    required this.reviews,
    required this.section,
  });

  final bool isEntrySection;
  final bool isCaseSection;
  final bool isPublications;
  final bool isReviews;
  final AsyncValue<List<ElogEntry>>? entries;
  final AsyncValue<List<ClinicalCase>>? cases;
  final AsyncValue<List<dynamic>>? publications;
  final ReviewQueueState? reviews;
  final String section;

  @override
  Widget build(BuildContext context) {
    if (isEntrySection && entries != null) {
      return entries!.when(
        data: (list) {
          if (list.isEmpty) {
            return _EmptyState(
              icon: Icons.library_books_outlined,
              title: 'No entries yet',
              subtitle: 'Tap "New Entry" to create your first logbook entry',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = list[index];
              return EntryCard(
                entry: entry,
                onTap: () => context.pushNamed(
                  'logbookDetail',
                  pathParameters: {'id': entry.id},
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF0B5FFF),
          ),
        ),
        error: (e, _) => _ErrorState(message: e.toString()),
      );
    }

    if (isCaseSection && cases != null) {
      return cases!.when(
        data: (list) {
          final filtered = _filterCasesForSection(list);
          if (filtered.isEmpty) {
            return _EmptyState(
              icon: Icons.medical_information_outlined,
              title: 'No cases yet',
              subtitle: 'Tap "New Entry" to create your first case',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final c = filtered[index];
              return Card(
                child: ListTile(
                  title: Text(c.patientName),
                  subtitle: Text('UID ${c.uidNumber} | MR ${c.mrNumber}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/cases/${c.id}'),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF0B5FFF),
          ),
        ),
        error: (e, _) => _ErrorState(message: e.toString()),
      );
    }

    if (isPublications && publications != null) {
      return publications!.when(
        data: (items) {
          if (items.isEmpty) {
            return _EmptyState(
              icon: Icons.article_outlined,
              title: 'No publications yet',
              subtitle: 'Tap "New Entry" to add a publication',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index] as dynamic;
              return Card(
                child: ListTile(
                  title: Text(item.title),
                  subtitle: Text(item.type ?? 'publication'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.pushNamed(
                    'pubDetail',
                    pathParameters: {'id': item.id},
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: e.toString()),
      );
    }

    if (isReviews && reviews != null) {
      if (reviews!.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (reviews!.error != null) {
        return _ErrorState(message: reviews!.error!);
      }
      if (reviews!.entries.isEmpty) {
        return _EmptyState(
          icon: Icons.rate_review_outlined,
          title: 'No reviews pending',
          subtitle: 'You have no submissions to review right now.',
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: reviews!.entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final entry = reviews!.entries[index];
          return Card(
            child: ListTile(
              title: Text(entry.patientUniqueId),
              subtitle: Text('MRN ${entry.mrn} | ${entry.moduleType}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.pushNamed(
                'reviewDetail',
                pathParameters: {'id': entry.id},
              ),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  List<ClinicalCase> _filterCasesForSection(List<ClinicalCase> list) {
    switch (section) {
      case logbookSectionRetinoblastoma:
        return list
            .where((c) => _hasKeyword(c, 'retinoblastoma'))
            .toList();
      case logbookSectionRop:
        return list.where((c) => _hasKeyword(c, 'rop')).toList();
      case logbookSectionOpdCases:
        return list
            .where(
              (c) =>
                  !_hasKeyword(c, 'retinoblastoma') &&
                  !_hasKeyword(c, 'rop'),
            )
            .toList();
    }
    return list;
  }

  bool _hasKeyword(ClinicalCase c, String keyword) {
    final target = keyword.toLowerCase();
    return c.keywords.any((k) => k.toLowerCase() == target);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
