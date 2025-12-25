import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/teaching_controller.dart';
import '../data/teaching_repository.dart';
import '../proposal_screens.dart';

class TeachingListScreen extends ConsumerStatefulWidget {
  const TeachingListScreen({super.key});

  @override
  ConsumerState<TeachingListScreen> createState() => _TeachingListScreenState();
}

class _TeachingListScreenState extends ConsumerState<TeachingListScreen> {
  String? module;
  String? scope;
  String keyword = '';

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(
      teachingListProvider(
        TeachingListParams(module: module, scope: scope, keyword: keyword),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teaching Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inbox),
            onPressed: () => context.pushNamed('teachingProposals'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              children: [
                _Chip('Cases', module == 'cases', () => setState(() => module = 'cases')),
                _Chip('Images', module == 'images', () => setState(() => module = 'images')),
                _Chip('Learning', module == 'learning', () => setState(() => module = 'learning')),
                _Chip('Records', module == 'records', () => setState(() => module = 'records')),
                _Chip('All', module == null, () => setState(() => module = null)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _Chip('Private', scope == 'private', () => setState(() => scope = 'private')),
                _Chip('Centre', scope == 'centre', () => setState(() => scope = 'centre')),
                _Chip('Institution', scope == 'institution', () => setState(() => scope = 'institution')),
                _Chip('Any', scope == null, () => setState(() => scope = null)),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search keyword',
              ),
              onChanged: (v) => setState(() => keyword = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const Center(child: Text('No teaching items'));
                  }
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return ListTile(
                        tileColor: Theme.of(context).colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                        title: Text(item.title),
                        subtitle: Text('${item.moduleType} • ${item.shareScope}'),
                        onTap: () => context.pushNamed(
                          'teachingDetail',
                          pathParameters: {'id': item.id},
                          extra: item,
                        ),
                      );
                    },
                  );
                },
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

class TeachingDetailScreen extends StatelessWidget {
  const TeachingDetailScreen({super.key, required this.item});
  final TeachingItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Module: ${item.moduleType} • Scope: ${item.shareScope}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: item.keywords
                  .map((k) => Chip(
                        label: Text(k),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Text(item.redactedPayload.toString()),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.selected, this.onTap);
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
  }
}
