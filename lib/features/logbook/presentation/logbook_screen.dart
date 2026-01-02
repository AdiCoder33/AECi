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
                if (isCaseSection) ...[
                  const SizedBox(height: 16),
                  _DiagnosisSearchBar(
                    onChanged: (value) =>
                        ref.read(diagnosisSearchProvider.notifier).state = value,
                  ),
                ],
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
      height: 48,
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
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Card with shadow effect
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: selected ? 36 : 32,
              margin: EdgeInsets.only(
                top: selected ? 0 : 2,
                bottom: 0,
              ),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF0B5FFF) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? const Color(0xFF0B5FFF).withOpacity(0.25)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: selected ? 8 : 3,
                    offset: Offset(0, selected ? 2 : 1),
                  ),
                ],
                border: Border.all(
                  color: selected
                      ? const Color(0xFF0B5FFF)
                      : Colors.grey[300]!,
                  width: selected ? 1.5 : 0.5,
                ),
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: selected ? 1.0 : 0.4,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: selected ? 10 : 8,
                    vertical: 6,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF64748B),
                        fontSize: selected ? 11 : 10,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
          return _CaseListView(cases: filtered);
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

class _DiagnosisSearchBar extends StatelessWidget {
  const _DiagnosisSearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF94A3B8),
            size: 22,
          ),
          hintText: 'Search by diagnosis...',
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

class _CaseListView extends ConsumerWidget {
  const _CaseListView({required this.cases});

  final List<ClinicalCase> cases;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(diagnosisSearchProvider).toLowerCase();
    
    // Filter by diagnosis search
    var filtered = cases;
    if (searchQuery.isNotEmpty) {
      filtered = cases
          .where((c) => c.diagnosis.toLowerCase().contains(searchQuery))
          .toList();
    }

    if (filtered.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No cases match your search',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      );
    }

    // Group by diagnosis
    final grouped = <String, List<ClinicalCase>>{};
    for (final c in filtered) {
      grouped.putIfAbsent(c.diagnosis, () => []).add(c);
    }

    final diagnoses = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: diagnoses.length,
      itemBuilder: (context, index) {
        final diagnosis = diagnoses[index];
        final casesForDiagnosis = grouped[diagnosis]!;
        
        return _DiagnosisGroup(
          diagnosis: diagnosis,
          cases: casesForDiagnosis,
          isExpanded: searchQuery.isNotEmpty || diagnoses.length <= 3,
        );
      },
    );
  }
}

class _DiagnosisGroup extends StatefulWidget {
  const _DiagnosisGroup({
    required this.diagnosis,
    required this.cases,
    this.isExpanded = false,
  });

  final String diagnosis;
  final List<ClinicalCase> cases;
  final bool isExpanded;

  @override
  State<_DiagnosisGroup> createState() => _DiagnosisGroupState();
}

class _DiagnosisGroupState extends State<_DiagnosisGroup> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0B5FFF).withOpacity(0.1),
                    const Color(0xFF0B5FFF).withOpacity(0.05),
                  ],
                ),
                borderRadius: _isExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(16))
                    : BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B5FFF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.medical_information,
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
                          widget.diagnosis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.cases.length} ${widget.cases.length == 1 ? 'case' : 'cases'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Column(
              children: widget.cases.map((c) {
                return _CaseCard(case_: c);
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.case_});

  final ClinicalCase case_;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/cases/${case_.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text(
                  case_.patientName.isNotEmpty 
                      ? case_.patientName[0].toUpperCase()
                      : 'P',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B5FFF),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          case_.patientName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      _StatusBadge(status: case_.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'UID: ${case_.uidNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.medical_services_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'MR: ${case_.mrNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(case_.dateOfExamination),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (case_.patientAge > 0) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${case_.patientAge} yrs',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isDraft = status == 'draft';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDraft 
            ? Colors.orange.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isDraft ? 'Draft' : 'Submitted',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDraft ? Colors.orange[700] : Colors.green[700],
        ),
      ),
    );
  }
}
