import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/review_controller.dart';
import '../../logbook/presentation/widgets/entry_card.dart';

class ReviewQueueScreen extends ConsumerStatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  ConsumerState<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends ConsumerState<ReviewQueueScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(reviewControllerProvider.notifier).loadQueue(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Review Queue')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null
                ? Center(child: Text('Error: ${state.error}'))
                : state.entries.isEmpty
                    ? const Center(child: Text('No submitted entries'))
                    : ListView.separated(
                        itemCount: state.entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final entry = state.entries[index];
                          return EntryCard(
                            entry: entry,
                            onTap: () => context.pushNamed(
                              'reviewDetail',
                              pathParameters: {'id': entry.id},
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
