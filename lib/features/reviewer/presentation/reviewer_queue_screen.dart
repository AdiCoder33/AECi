import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/reviewer_controller.dart';
import '../../profile/application/profile_controller.dart';
import 'widgets/reviewer_app_bar_actions.dart';

class ReviewerQueueScreen extends ConsumerWidget {
  const ReviewerQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final isReviewer = profileState.profile?.designation == 'Reviewer';
    final pendingAsync = ref.watch(reviewerPendingProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles to Assess'),
        actions: const [ReviewerAppBarActions()],
      ),
      body: !isReviewer
          ? const Center(child: Text('Reviewer access only.'))
          : pendingAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No pending reviews right now.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isCase = item.entityType == 'clinical_case';
                    final icon =
                        isCase ? Icons.note_alt : Icons.play_circle_outline;
                    return Card(
                      child: ListTile(
                        leading: Icon(icon),
                        title: Text(item.title),
                        subtitle: Text(item.subtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          '/reviewer/pending/assess/${item.entityType}/${item.entityId}',
                          extra: item,
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load: $e')),
            ),
    );
  }
}
