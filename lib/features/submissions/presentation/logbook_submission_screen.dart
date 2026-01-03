import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../clinical_cases/data/clinical_cases_repository.dart';
import '../../community/application/community_controller.dart';
import '../../logbook/domain/elog_entry.dart';
import '../../logbook/domain/logbook_sections.dart';
import '../../portfolio/data/portfolio_repository.dart';
import '../../profile/data/profile_model.dart';
import '../../review/application/review_controller.dart';
import '../application/logbook_submission_controller.dart';
import '../data/logbook_submission_repository.dart';

class LogbookSubmissionScreen extends ConsumerStatefulWidget {
  const LogbookSubmissionScreen({super.key});

  @override
  ConsumerState<LogbookSubmissionScreen> createState() =>
      _LogbookSubmissionScreenState();
}

class _LogbookSubmissionScreenState
    extends ConsumerState<LogbookSubmissionScreen> {
  final PageController _pageController = PageController();
  final Map<String, Set<String>> _selectedBySection = {};
  final Set<String> _selectedRecipients = {};
  final TextEditingController _searchController = TextEditingController();

  int _pageIndex = 0;
  bool _reviewsLoaded = false;

  List<LogbookSection> get _sections => logbookSections
      .where((s) => s.key != logbookSectionLearning)
      .toList();

  int get _totalPages => _sections.length + 1;

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mutation = ref.watch(logbookSubmissionProvider);
    final profilesAsync = ref.watch(communityProfilesProvider);
    final onRecipientsPage = _pageIndex == _sections.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Logbook'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _WizardHeader(step: _pageIndex, total: _totalPages),
            if (!onRecipientsPage)
              _SectionTabs(
                sections: _sections,
                activeIndex: _pageIndex,
                onTap: (index) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _totalPages,
                onPageChanged: (index) {
                  setState(() => _pageIndex = index);
                  final reviewIndex =
                      _sections.indexWhere((s) => s.key == logbookSectionReviews);
                  if (!_reviewsLoaded && index == reviewIndex) {
                    _reviewsLoaded = true;
                    ref.read(reviewControllerProvider.notifier).loadQueue();
                  }
                },
                itemBuilder: (context, index) {
                  if (index == _sections.length) {
                    return _RecipientStep(
                      profilesAsync: profilesAsync,
                      searchController: _searchController,
                      onQueryChanged: () => setState(() {}),
                      selected: _selectedRecipients,
                      onToggle: (id) => setState(() {
                        if (_selectedRecipients.contains(id)) {
                          _selectedRecipients.remove(id);
                        } else {
                          _selectedRecipients.add(id);
                        }
                      }),
                    );
                  }
                  final section = _sections[index];
                  return _buildSectionPage(section);
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  if (_pageIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_pageIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: mutation.isLoading
                          ? null
                          : onRecipientsPage
                              ? _canSubmit()
                                  ? () async => _submit()
                                  : null
                              : () => _pageController.nextPage(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                  ),
                      child: mutation.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(onRecipientsPage ? 'Submit' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionPage(LogbookSection section) {
    switch (section.key) {
      case logbookSectionOpdCases:
      case logbookSectionRetinoblastoma:
      case logbookSectionRop:
      case logbookSectionLaser:
      case logbookSectionUvea:
        final casesAsync = ref.watch(submissionCasesProvider);
        return casesAsync.when(
          data: (cases) {
            final filtered = _filterCasesForSection(cases, section.key);
            return _SectionSelectionPage(
              title: 'Select ${section.label}',
              items: filtered
                  .map(
                    (c) => _SelectableRow(
                      id: c.id,
                      title: c.patientName,
                      subtitle: 'UID ${c.uidNumber} | MR ${c.mrNumber}',
                    ),
                  )
                  .toList(),
              selected: _selectedBySection[section.key] ?? <String>{},
              onToggle: (id) => _toggleSection(section.key, id),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(message: e.toString()),
        );
      case logbookSectionAtlas:
        return _buildEntrySection(section, moduleImages);
      case logbookSectionSurgicalRecord:
        return _buildEntrySection(section, moduleRecords);
      case logbookSectionPublications:
        final pubsAsync = ref.watch(submissionPublicationsProvider);
        return pubsAsync.when(
          data: (items) => _SectionSelectionPage(
            title: 'Select ${section.label}',
            items: items
                .map(
                  (p) => _SelectableRow(
                    id: p.id,
                    title: p.title,
                    subtitle: p.type,
                  ),
                )
                .toList(),
            selected: _selectedBySection[section.key] ?? <String>{},
            onToggle: (id) => _toggleSection(section.key, id),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(message: e.toString()),
        );
      case logbookSectionReviews:
        final reviews = ref.watch(reviewControllerProvider);
        if (reviews.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (reviews.error != null) {
          return _ErrorState(message: reviews.error!);
        }
        return _SectionSelectionPage(
          title: 'Select ${section.label}',
          items: reviews.entries
              .map(
                (e) => _SelectableRow(
                  id: e.id,
                  title: e.patientUniqueId,
                  subtitle: 'MRN ${e.mrn} | ${e.moduleType}',
                ),
              )
              .toList(),
          selected: _selectedBySection[section.key] ?? <String>{},
          onToggle: (id) => _toggleSection(section.key, id),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEntrySection(LogbookSection section, String module) {
    final entriesAsync = ref.watch(submissionEntriesProvider(module));
    return entriesAsync.when(
      data: (entries) => _SectionSelectionPage(
        title: 'Select ${section.label}',
        items: entries
            .map(
              (e) => _SelectableRow(
                id: e.id,
                title: e.patientUniqueId,
                subtitle: 'MRN ${e.mrn}',
              ),
            )
            .toList(),
        selected: _selectedBySection[section.key] ?? <String>{},
        onToggle: (id) => _toggleSection(section.key, id),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(message: e.toString()),
    );
  }

  void _toggleSection(String sectionKey, String id) {
    setState(() {
      final set = _selectedBySection.putIfAbsent(sectionKey, () => <String>{});
      if (set.contains(id)) {
        set.remove(id);
      } else {
        set.add(id);
      }
    });
  }

  bool _canSubmit() {
    final totalSelected =
        _selectedBySection.values.fold<int>(0, (sum, set) => sum + set.length);
    return totalSelected > 0 && _selectedRecipients.isNotEmpty;
  }

  Future<void> _submit() async {
    try {
      final moduleKeys = _sections
          .where(
            (s) => (_selectedBySection[s.key]?.isNotEmpty ?? false),
          )
          .map((s) => s.key)
          .toList();
      final items = <LogbookSubmissionItem>[];
      final seen = <String>{};
      for (final section in _sections) {
        final ids = _selectedBySection[section.key] ?? <String>{};
        if (ids.isEmpty) continue;
        final entityType = _entityTypeForSection(section.key);
        for (final id in ids) {
          final dedupeKey = '$entityType|$id';
          if (!seen.add(dedupeKey)) continue;
          items.add(
            LogbookSubmissionItem(
              moduleKey: section.key,
              entityType: entityType,
              entityId: id,
            ),
          );
        }
      }

      await ref.read(logbookSubmissionProvider.notifier).submit(
            moduleKeys: moduleKeys,
            recipientIds: _selectedRecipients.toList(),
            items: items,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission sent')),
      );
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    }
  }

  String _entityTypeForSection(String sectionKey) {
    switch (sectionKey) {
      case logbookSectionAtlas:
      case logbookSectionSurgicalRecord:
      case logbookSectionReviews:
        return 'elog_entry';
      case logbookSectionPublications:
        return 'publication';
      case logbookSectionOpdCases:
      case logbookSectionRetinoblastoma:
      case logbookSectionRop:
      case logbookSectionLaser:
      case logbookSectionUvea:
      default:
        return 'clinical_case';
    }
  }

  List<ClinicalCase> _filterCasesForSection(
    List<ClinicalCase> cases,
    String sectionKey,
  ) {
    switch (sectionKey) {
      case logbookSectionRetinoblastoma:
        return cases.where((c) => _hasKeyword(c, 'retinoblastoma')).toList();
      case logbookSectionRop:
        return cases.where((c) => _hasKeyword(c, 'rop')).toList();
      case logbookSectionLaser:
        return cases.where((c) => _hasKeyword(c, 'laser')).toList();
      case logbookSectionUvea:
        return cases.where((c) => _hasKeyword(c, 'uvea')).toList();
      case logbookSectionOpdCases:
        return cases
            .where(
              (c) =>
                  !_hasKeyword(c, 'retinoblastoma') &&
                  !_hasKeyword(c, 'rop') &&
                  !_hasKeyword(c, 'laser') &&
                  !_hasKeyword(c, 'uvea'),
            )
            .toList();
    }
    return cases;
  }

  bool _hasKeyword(ClinicalCase c, String keyword) {
    final target = keyword.toLowerCase();
    return c.keywords.any((k) => k.toLowerCase() == target);
  }
}

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${step + 1} of $total',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (step + 1) / total,
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}

class _SectionTabs extends StatelessWidget {
  const _SectionTabs({
    required this.sections,
    required this.activeIndex,
    required this.onTap,
  });

  final List<LogbookSection> sections;
  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(sections.length, (index) {
          final section = sections[index];
          final selected = index == activeIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(section.label),
              selected: selected,
              onSelected: (_) => onTap(index),
            ),
          );
        }),
      ),
    );
  }
}

class _SelectableRow {
  const _SelectableRow({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;
}

class _SectionSelectionPage extends StatelessWidget {
  const _SectionSelectionPage({
    required this.title,
    required this.items,
    required this.selected,
    required this.onToggle,
  });

  final String title;
  final List<_SelectableRow> items;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Text('No items available.')
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = selected.contains(item.id);
              return CheckboxListTile(
                value: isSelected,
                title: Text(item.title),
                subtitle: Text(item.subtitle),
                onChanged: (_) => onToggle(item.id),
              );
            },
          ),
        const SizedBox(height: 12),
        Text(
          'Selected: ${selected.length}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _RecipientStep extends StatelessWidget {
  const _RecipientStep({
    required this.profilesAsync,
    required this.searchController,
    required this.onQueryChanged,
    required this.selected,
    required this.onToggle,
  });

  final AsyncValue<List<Profile>> profilesAsync;
  final TextEditingController searchController;
  final VoidCallback onQueryChanged;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Choose people to share with',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: searchController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search doctors by name or designation',
          ),
          onChanged: (_) => onQueryChanged(),
        ),
        const SizedBox(height: 12),
        profilesAsync.when(
          data: (list) {
            final filtered = query.isEmpty
                ? list
                : list.where((p) {
                    final centre = p.aravindCentre ?? p.centre;
                    return p.name.toLowerCase().contains(query) ||
                        p.designation.toLowerCase().contains(query) ||
                        centre.toLowerCase().contains(query);
                  }).toList();
            if (filtered.isEmpty) {
              return const Text('No doctors found.');
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final profile = filtered[index];
                final isSelected = selected.contains(profile.id);
                final centre = profile.aravindCentre ?? profile.centre;
                return CheckboxListTile(
                  value: isSelected,
                  title: Text(profile.name),
                  subtitle: Text('${profile.designation} | $centre'),
                  onChanged: (_) => onToggle(profile.id),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Failed to load doctors: $e'),
        ),
        const SizedBox(height: 12),
        Text(
          'Selected: ${selected.length}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        padding: const EdgeInsets.all(16),
        child: Text('Failed to load: $message'),
      ),
    );
  }
}
