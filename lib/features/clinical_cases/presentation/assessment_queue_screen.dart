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
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Assessment Queue'),
        iconTheme: const IconThemeData(color: Color(0xFF0B5FFF)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF0B5FFF),
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      body: !isConsultant
          ? const Center(
              child: Text(
                'Consultant access only.',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : queueAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No pending assessments.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You have no cases to assess right now.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF94A3B8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.go('/cases/${item.caseId}'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF0B5FFF).withOpacity(0.1),
                                child: const Icon(Icons.person, color: Color(0xFF0B5FFF)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.patientName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF0B172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'UID ${item.uidNumber}  •  MR ${item.mrNumber}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Color(0xFF0B5FFF)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF0B5FFF)),
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
                      'Failed to load queue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
