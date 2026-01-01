import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/community_controller.dart';
import '../../profile/data/profile_model.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(communityFilterProvider);
    final profilesAsync = ref.watch(communityProfilesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _FilterChips(
              selected: filter,
              onChanged: (value) =>
                  ref.read(communityFilterProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: profilesAsync.when(
              data: (profiles) {
                final filtered = filter == 'All'
                    ? profiles
                    : profiles
                        .where((p) => p.designation == filter)
                        .toList();
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No profiles found.'),
                  );
                }
                final grouped = _groupByDesignation(filtered);
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final entry = grouped[index];
                    return _DesignationSection(
                      designation: entry.key,
                      profiles: entry.value,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Failed to load community: $e',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, List<Profile>>> _groupByDesignation(
    List<Profile> profiles,
  ) {
    final map = <String, List<Profile>>{};
    for (final profile in profiles) {
      map.putIfAbsent(profile.designation, () => []).add(profile);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    final ordered = <MapEntry<String, List<Profile>>>[];
    for (final designation in communityDesignationOrder) {
      if (map.containsKey(designation)) {
        ordered.add(MapEntry(designation, map[designation]!));
        map.remove(designation);
      }
    }
    final remainingKeys = map.keys.toList()..sort();
    for (final key in remainingKeys) {
      ordered.add(MapEntry(key, map[key]!));
    }
    return ordered;
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      'All',
      'Consultant',
      'Reviewer',
      'Fellow',
      'Resident',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options
            .map(
              (option) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(option),
                  selected: selected == option,
                  onSelected: (_) => onChanged(option),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DesignationSection extends StatelessWidget {
  const _DesignationSection({
    required this.designation,
    required this.profiles,
  });

  final String designation;
  final List<Profile> profiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            designation,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...profiles.map(
            (profile) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        theme.colorScheme.primary.withOpacity(0.12),
                    foregroundColor: theme.colorScheme.primary,
                    child: Text(_initials(profile.name)),
                  ),
                  title: Text(profile.name),
                  subtitle: Text(
                    [
                      profile.designation,
                      (profile.aravindCentre ?? profile.centre),
                    ].where((e) => e.isNotEmpty).join(' | '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/community/${profile.id}'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
