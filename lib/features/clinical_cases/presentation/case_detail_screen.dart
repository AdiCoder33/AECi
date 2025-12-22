import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/clinical_cases_controller.dart';
import '../application/assessment_controller.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/application/profile_controller.dart';
import '../data/assessment_repository.dart';

class ClinicalCaseDetailScreen extends ConsumerWidget {
  const ClinicalCaseDetailScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseAsync = ref.watch(clinicalCaseDetailProvider(caseId));
    final assessmentAsync = ref.watch(caseAssessmentProvider(caseId));
    final profileState = ref.watch(profileControllerProvider);
    final isConsultant =
        profileState.profile?.designation == 'Consultant';
    return Scaffold(
      appBar: AppBar(title: const Text('Case Detail')),
      body: caseAsync.when(
        data: (c) {
          return DefaultTabController(
            length: 4,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Summary'),
                    Tab(text: 'Follow-ups'),
                    Tab(text: 'Media'),
                    Tab(text: 'Assessment'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _SummaryTab(c: c),
                      _FollowupsTab(caseId: caseId),
                      _MediaTab(caseId: caseId),
                      assessmentAsync.when(
                        data: (a) => _AssessmentTab(
                          caseId: caseId,
                          assessment: a,
                          isConsultant: isConsultant,
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({required this.c});
  final dynamic c;
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Patient: ${c.patientName}'),
        Text('UID: ${c.uidNumber} • MR: ${c.mrNumber}'),
        Text('Chief complaint: ${c.chiefComplaint}'),
        Text('Diagnosis: ${c.diagnosis}${c.diagnosisOther != null ? " (${c.diagnosisOther})" : ""}'),
        Text('Management: ${c.management ?? ""}'),
        Text('Learning: ${c.learningPoint ?? ""}'),
        Wrap(
          spacing: 6,
          children: c.keywords.map<Widget>((k) => Chip(label: Text(k))).toList(),
        ),
      ],
    );
  }
}

class _FollowupsTab extends StatelessWidget {
  const _FollowupsTab({required this.caseId});
  final String caseId;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Follow-ups'),
          ElevatedButton(
            onPressed: () => context.push('/cases/$caseId/followup'),
            child: const Text('Add Follow-up'),
          ),
        ],
      ),
    );
  }
}

class _MediaTab extends StatelessWidget {
  const _MediaTab({required this.caseId});
  final String caseId;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => context.push('/cases/$caseId/media'),
        child: const Text('Add Media'),
      ),
    );
  }
}

class _AssessmentTab extends ConsumerStatefulWidget {
  const _AssessmentTab({
    required this.caseId,
    required this.assessment,
    required this.isConsultant,
  });
  final String caseId;
  final dynamic assessment;
  final bool isConsultant;

  @override
  ConsumerState<_AssessmentTab> createState() => _AssessmentTabState();
}

class _AssessmentTabState extends ConsumerState<_AssessmentTab> {
  final _comments = TextEditingController();
  String? _selectedConsultant;

  @override
  Widget build(BuildContext context) {
    final mutation = ref.watch(assessmentMutationProvider);
    final assessment = widget.assessment;
    if (assessment == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Submit for assessment'),
            DropdownButtonFormField<String>(
              value: _selectedConsultant,
              items: const [],
              onChanged: (v) => setState(() => _selectedConsultant = v),
              decoration: const InputDecoration(labelText: 'Consultant'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _selectedConsultant == null
                  ? null
                  : () async {
                      await ref
                          .read(assessmentMutationProvider.notifier)
                          .submit(widget.caseId, _selectedConsultant!);
                    },
              child: const Text('Submit'),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status: ${assessment.status}'),
          Text('Consultant comments: ${assessment.consultantComments ?? ""}'),
          if (widget.isConsultant && assessment.status != 'completed') ...[
            TextField(
              controller: _comments,
              decoration: const InputDecoration(labelText: 'Comments'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: mutation.isLoading
                  ? null
                  : () async {
                      await ref
                          .read(assessmentMutationProvider.notifier)
                          .complete(assessment.id, _comments.text);
                    },
              child: const Text('Mark complete'),
            ),
          ],
        ],
      ),
    );
  }
}
