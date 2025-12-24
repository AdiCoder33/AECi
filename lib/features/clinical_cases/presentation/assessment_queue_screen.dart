import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/assessment_controller.dart';
import '../../profile/application/profile_controller.dart';

class AssessmentQueueScreen extends ConsumerWidget {
  const AssessmentQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final isConsultant = profileState.profile?.designation == 'Consultant';
    final queueAsync = ref.watch(assessmentQueueProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Assessment Queue')),
      body: !isConsultant
          ? const Center(child: Text('Consultant access only.'))
          : queueAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text('No pending assessments.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return Card(
                      child: ListTile(
                        title: Text(item.patientName),
                        subtitle: Text(
                          'UID ${item.uidNumber} - MR ${item.mrNumber}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/cases/${item.caseId}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
    );
  }
}
