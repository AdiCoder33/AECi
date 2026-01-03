import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/shimmer_loading.dart';

import '../../clinical_cases/application/clinical_cases_controller.dart';
import '../../clinical_cases/data/clinical_cases_repository.dart';
import '../../portfolio/application/portfolio_controller.dart';
import '../../review/application/review_controller.dart';
import '../application/logbook_providers.dart';
import '../domain/elog_entry.dart';
import '../domain/logbook_sections.dart';
import 'widgets/entry_card.dart';

// Providers for OPD cases filtering
final expandedDiagnosisProvider = StateProvider<Set<String>>((ref) => {});
final diagnosisSearchProvider = StateProvider<String>((ref) => '');

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
                : section == logbookSectionLaser
                    ? ref.watch(clinicalCaseListByKeywordProvider('laser'))
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.library_books_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Logbook',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () => context.push('/search'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton(
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
            case logbookSectionLaser:
              context.push('/cases/new?type=laser');
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
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 4,
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
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

class _SectionSelector extends StatefulWidget {
  const _SectionSelector({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  State<_SectionSelector> createState() => _SectionSelectorState();
}

class _SectionSelectorState extends State<_SectionSelector> {
  late ScrollController _scrollController;
  late PageController _pageController;
  static const int itemsPerPage = 3;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _pageController = PageController(
      viewportFraction: 0.33, // Show 3 items
      initialPage: _getInitialPage(),
    );
  }

  int _getInitialPage() {
    final index = logbookSections.indexWhere((s) => s.key == widget.selected);
    return index >= 0 ? index : 0;
  }

  @override
  void didUpdateWidget(_SectionSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      final index = logbookSections.indexWhere((s) => s.key == widget.selected);
      if (index >= 0 && _pageController.hasClients) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: PageView.builder(
        controller: _pageController,
        itemCount: logbookSections.length,
        onPageChanged: (index) {
          widget.onChanged(logbookSections[index].key);
        },
        itemBuilder: (context, index) {
          final section = logbookSections[index];
          final isSelected = widget.selected == section.key;
          return _ModuleChip(
            label: section.label,
            selected: isSelected,
            onTap: () {
              if (!isSelected) {
                widget.onChanged(section.key);
              }
            },
          );
        },
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
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Card with gradient and shadow effect
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: EdgeInsets.only(
                  top: selected ? 0 : 4,
                  bottom: selected ? 0 : 4,
                ),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: selected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: selected
                          ? const Color(0xFF3B82F6).withOpacity(0.4)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: selected ? 12 : 6,
                      offset: Offset(0, selected ? 4 : 2),
                      spreadRadius: selected ? 1 : 0,
                    ),
                  ],
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : const Color(0xFFE2E8F0),
                    width: selected ? 0 : 1,
                  ),
                ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: 1.0,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: selected ? 16 : 12,
                        vertical: selected ? 12 : 10,
                      ),
                      child: Center(
                        child: Text(
                          label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? Colors.white : const Color(0xFF64748B),
                          fontSize: selected ? 13 : 12,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Connector line for selected
              if (selected)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 3,
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF3B82F6),
                        const Color(0xFF3B82F6).withOpacity(0),
                      ],
                    ),
                  ),
                ),
            ],
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
      backgroundColor: const Color(0xFFF8FAFC),
      selectedColor: const Color(0xFF3B82F6).withOpacity(0.15),
      checkmarkColor: const Color(0xFF3B82F6),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
        fontSize: 13,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        letterSpacing: 0.2,
      ),
      side: BorderSide(
        color: selected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
        width: selected ? 2 : 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      elevation: selected ? 2 : 0,
      shadowColor: selected ? const Color(0xFF3B82F6).withOpacity(0.3) : null,
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
        loading: () => const ShimmerLoadingList(),
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
          
          // For OPD cases, show diagnosis groups
          if (section == logbookSectionOpdCases) {
            return _OpdCasesList(cases: filtered);
          }
          
          // For other case sections, show normal list
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final c = filtered[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      switch (section) {
                        case logbookSectionRop:
                          context.push('/cases/rop/${c.id}');
                          return;
                        case logbookSectionRetinoblastoma:
                          context.push('/cases/retinoblastoma/${c.id}');
                          return;
                        case logbookSectionLaser:
                          context.push('/cases/laser/${c.id}');
                          return;
                        default:
                          context.push('/cases/${c.id}');
                          return;
                      }
                    },
                    child: Column(
                      children: [
                        // Gradient Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.medical_information_outlined,
                                  color: Color(0xFF3B82F6),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  c.patientName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFF3B82F6).withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.fingerprint,
                                            size: 14,
                                            color: Color(0xFF3B82F6),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'UID ${c.uidNumber}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF3B82F6),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.badge_outlined,
                                            size: 14,
                                            color: Color(0xFF64748B),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'MR ${c.mrNumber}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const ShimmerLoadingList(),
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
        loading: () => const ShimmerLoadingList(itemCount: 3),
        error: (e, _) => _ErrorState(message: e.toString()),
      );
    }

    if (isReviews && reviews != null) {
      if (reviews!.isLoading) {
        return const ShimmerLoadingList(itemCount: 3);
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
      case logbookSectionLaser:
        return list.where((c) => _hasKeyword(c, 'laser')).toList();
      case logbookSectionOpdCases:
        return list
            .where(
              (c) =>
                  !_hasKeyword(c, 'retinoblastoma') &&
                  !_hasKeyword(c, 'rop') &&
                  !_hasKeyword(c, 'laser'),
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
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OpdCasesList extends ConsumerWidget {
  const _OpdCasesList({required this.cases});

  final List<ClinicalCase> cases;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(diagnosisSearchProvider);
    final expandedDiagnoses = ref.watch(expandedDiagnosisProvider);

    // Group cases by diagnosis
    final diagnosisMap = <String, List<ClinicalCase>>{};
    for (final c in cases) {
      diagnosisMap.putIfAbsent(c.diagnosis, () => []).add(c);
    }

    // Sort diagnoses alphabetically
    final sortedDiagnoses = diagnosisMap.keys.toList()..sort();

    // Filter by search query
    final filteredDiagnoses = searchQuery.isEmpty
        ? sortedDiagnoses
        : sortedDiagnoses
            .where((d) => d.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

    return Column(
      children: [
        // Search bar
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Color(0xFF94A3B8),
                size: 22,
              ),
              hintText: 'Search diagnosis...',
              hintStyle: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 14,
            ),
            onChanged: (value) =>
                ref.read(diagnosisSearchProvider.notifier).state = value,
          ),
        ),
        // Diagnosis list
        Expanded(
          child: filteredDiagnoses.isEmpty
              ? const Center(
                  child: Text(
                    'No diagnosis found',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filteredDiagnoses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final diagnosis = filteredDiagnoses[index];
                    final diagnosisCases = diagnosisMap[diagnosis]!;
                    final isExpanded = expandedDiagnoses.contains(diagnosis);

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Diagnosis header with gradient
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              onTap: () {
                                final updated = Set<String>.from(expandedDiagnoses);
                                if (isExpanded) {
                                  updated.remove(diagnosis);
                                } else {
                                  updated.add(diagnosis);
                                }
                                ref.read(expandedDiagnosisProvider.notifier).state = updated;
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isExpanded
                                        ? [const Color(0xFF3B82F6), const Color(0xFF60A5FA)]
                                        : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: isExpanded ? Radius.zero : const Radius.circular(16),
                                    bottomRight: isExpanded ? Radius.zero : const Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isExpanded
                                            ? Colors.white
                                            : const Color(0xFF3B82F6).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: isExpanded
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Icon(
                                        Icons.local_hospital_rounded,
                                        color: const Color(0xFF3B82F6),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            diagnosis,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: isExpanded ? Colors.white : const Color(0xFF1E293B),
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isExpanded
                                                  ? Colors.white.withOpacity(0.25)
                                                  : const Color(0xFF3B82F6).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${diagnosisCases.length} ${diagnosisCases.length == 1 ? 'case' : 'cases'}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: isExpanded ? Colors.white : const Color(0xFF3B82F6),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      isExpanded
                                          ? Icons.expand_less_rounded
                                          : Icons.expand_more_rounded,
                                      color: isExpanded ? Colors.white : const Color(0xFF94A3B8),
                                      size: 28,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Cases list (when expanded)
                          if (isExpanded) ...[
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(12),
                              itemCount: diagnosisCases.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, caseIndex) {
                                final c = diagnosisCases[caseIndex];
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => context.push('/cases/${c.id}'),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(10),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.person_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    c.patientName,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                      color: Color(0xFF1E293B),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(
                                                            color: const Color(0xFF3B82F6).withOpacity(0.2),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            const Icon(
                                                              Icons.fingerprint,
                                                              size: 12,
                                                              color: Color(0xFF3B82F6),
                                                            ),
                                                            const SizedBox(width: 3),
                                                            Text(
                                                              c.uidNumber,
                                                              style: const TextStyle(
                                                                fontSize: 11,
                                                                color: Color(0xFF3B82F6),
                                                                fontWeight: FontWeight.w700,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFF1F5F9),
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(
                                                            color: const Color(0xFFE2E8F0),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            const Icon(
                                                              Icons.badge_outlined,
                                                              size: 12,
                                                              color: Color(0xFF64748B),
                                                            ),
                                                            const SizedBox(width: 3),
                                                            Text(
                                                              c.mrNumber,
                                                              style: const TextStyle(
                                                                fontSize: 11,
                                                                color: Color(0xFF64748B),
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  // Eye information side by side
                                                  // ...existing code...
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF3B82F6).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.chevron_right_rounded,
                                                color: Color(0xFF3B82F6),
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEF4444).withOpacity(0.1),
                    const Color(0xFFFEE2E2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.red[700],
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red[200]!,
                  width: 1,
                ),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
