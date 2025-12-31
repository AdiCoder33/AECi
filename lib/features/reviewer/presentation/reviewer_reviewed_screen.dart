import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/reviewer_controller.dart';
import '../../profile/application/profile_controller.dart';
import 'widgets/reviewer_app_bar_actions.dart';

class ReviewerReviewedScreen extends ConsumerWidget {
  const ReviewerReviewedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final isReviewer = profileState.profile?.designation == 'Reviewer';
    final reviewedAsync = ref.watch(reviewerReviewedProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles Reviewed'),
        actions: const [ReviewerAppBarActions()],
      ),
      body: !isReviewer
          ? const Center(child: Text('Reviewer access only.'))
          : reviewedAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No reviewed items yet.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final icon = item.entityType == 'clinical_case'
                        ? Icons.note_alt
                        : Icons.play_circle_outline;
                    return Card(
                      child: ListTile(
                        leading: Icon(icon),
                        title: Text(item.title),
                        subtitle: Text(item.subtitle),
                        trailing: item.score == null
                            ? null
                            : Text(
                                'Score ${item.score}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
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
