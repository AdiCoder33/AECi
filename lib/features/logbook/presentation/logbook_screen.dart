import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../application/logbook_providers.dart';
import '../domain/elog_entry.dart';
import 'widgets/entry_card.dart';

class LogbookScreen extends ConsumerWidget {
  const LogbookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = ref.watch(moduleSelectionProvider);
    final entries = ref.watch(entriesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logbook'),
        backgroundColor: AppTheme.dark.scaffoldBackgroundColor,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('logbookNew', extra: module),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _ModuleSelector(
              selected: module,
              onChanged: (value) =>
                  ref.read(moduleSelectionProvider.notifier).state = value,
            ),
            const SizedBox(height: 12),
            _SearchBar(
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).state = value,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: entries.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const Center(
                      child: Text('No entries yet. Tap + to add.'),
                    );
                  }
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'Failed to load entries: $e',
                    style: const TextStyle(color: Colors.redAccent),
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

class _ModuleSelector extends StatelessWidget {
  const _ModuleSelector({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: moduleTypes
          .map(
            (m) => ChoiceChip(
              label: Text(m.toUpperCase()),
              selected: selected == m,
              onSelected: (_) => onChanged(m),
            ),
          )
          .toList(),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Search by patient, MRN or keyword',
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: onChanged,
    );
  }
}
