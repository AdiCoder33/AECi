import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/consultant_assessments_controller.dart';

class ConsultantAssessmentsScreen extends ConsumerWidget {
  const ConsultantAssessmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Assessments'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Profiles to be assessed'),
              Tab(text: 'Profiles assessed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ProfilesTab(
              provider: consultantPendingProfilesProvider,
              emptyMessage: 'No profiles to be assessed yet.',
              countLabel: 'Pending',
            ),
            _ProfilesTab(
              provider: consultantReviewedProfilesProvider,
              emptyMessage: 'No profiles assessed yet.',
              countLabel: 'Reviewed',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilesTab extends ConsumerWidget {
  const _ProfilesTab({
    required this.provider,
    required this.emptyMessage,
    required this.countLabel,
  });

  final AutoDisposeFutureProvider<List<TraineeAssessmentGroup>> provider;
  final String emptyMessage;
  final String countLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    final theme = Theme.of(context);

    return async.when(
      data: (groups) {
        if (groups.isEmpty) {
          return Center(
            child: Text(
              emptyMessage,
              style: theme.textTheme.bodyMedium,
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final group = groups[index];
            return _TraineeCard(
              group: group,
              countLabel: countLabel,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Failed to load profiles: $e',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _TraineeCard extends StatelessWidget {
  const _TraineeCard({
    required this.group,
    required this.countLabel,
  });

  final TraineeAssessmentGroup group;
  final String countLabel;

  @override
  Widget build(BuildContext context) {
    final profile = group.profile;
    final subtitle = [
      profile.designation,
      (profile.aravindCentre ?? profile.centre),
      '$countLabel: ${group.count}',
    ].where((e) => e.trim().isNotEmpty).join(' | ');

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
          foregroundColor: Theme.of(context).colorScheme.primary,
          child: Text(_initials(profile.name)),
        ),
        title: Text(profile.name),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.pushNamed(
          'consultantAssessmentProfile',
          pathParameters: {'id': profile.id},
        ),
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
