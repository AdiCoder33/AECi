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
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Teaching Library',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.inbox, color: Color(0xFF64748B)),
            onPressed: () => context.pushNamed('teachingProposals'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ModuleChip('Cases', module == 'cases', () => setState(() => module = 'cases')),
                      const SizedBox(width: 8),
                      _ModuleChip('Images', module == 'images', () => setState(() => module = 'images')),
                      const SizedBox(width: 8),
                      _ModuleChip('Learning', module == 'learning', () => setState(() => module = 'learning')),
                      const SizedBox(width: 8),
                      _ModuleChip('Records', module == 'records', () => setState(() => module = 'records')),
                      const SizedBox(width: 8),
                      _ModuleChip('All', module == null, () => setState(() => module = null)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterChip('Private', scope == 'private', () => setState(() => scope = 'private')),
                    _FilterChip('Centre', scope == 'centre', () => setState(() => scope = 'centre')),
                    _FilterChip('Institution', scope == 'institution', () => setState(() => scope = 'institution')),
                    _FilterChip('Any', scope == null, () => setState(() => scope = null)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
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
                      hintText: 'Search by keyword...',
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
                    onChanged: (v) => setState(() => keyword = v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No teaching items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Teaching content will appear here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = list[index] as TeachingItem;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.pushNamed(
                          'teachingDetail',
                          pathParameters: {'id': item.id},
                          extra: item,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0B5FFF).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.moduleType.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0B5FFF),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.shareScope,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (item.keywords.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: item.keywords.take(3).map(
                                    (k) => Container(
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
                                      child: Text(
                                        k,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF475569),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
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
              error: (e, _) => Center(
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
                      'Failed to load teaching items',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        e.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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

class _ModuleChip extends StatelessWidget {
  const _ModuleChip(this.label, this.selected, this.onTap);
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
            color: selected ? const Color(0xFF0B5FFF) : Colors.grey[300]!,
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
  const _FilterChip(this.label, this.selected, this.onTap);
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
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
