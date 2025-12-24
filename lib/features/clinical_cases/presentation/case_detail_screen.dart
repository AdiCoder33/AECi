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
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Case Detail',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: caseAsync.when(
        data: (c) {
          return DefaultTabController(
            length: 4,
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  child: TabBar(
                    labelColor: const Color(0xFF0B5FFF),
                    unselectedLabelColor: const Color(0xFF64748B),
                    indicatorColor: const Color(0xFF0B5FFF),
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'Summary'),
                      Tab(text: 'Follow-ups'),
                      Tab(text: 'Media'),
                      Tab(text: 'Assessment'),
                    ],
                  ),
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
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0B5FFF),
                          ),
                        ),
                        error: (e, _) => Center(child: Text('Error: $e')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF0B5FFF),
          ),
        ),
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
        Container(
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B5FFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF0B5FFF),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Patient Information',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.patientName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.badge_outlined,
                label: 'UID',
                value: c.uidNumber,
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.medical_services_outlined,
                label: 'MR Number',
                value: c.mrNumber,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
              const Row(
                children: [
                  Icon(
                    Icons.medical_information_outlined,
                    color: Color(0xFF0B5FFF),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Clinical Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailItem(
                label: 'Chief Complaint',
                value: c.chiefComplaint,
              ),
              const SizedBox(height: 12),
              _DetailItem(
                label: 'Diagnosis',
                value: '${c.diagnosis}${c.diagnosisOther != null ? " (${c.diagnosisOther})" : ""}',
              ),
              if (c.management != null && c.management.toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                _DetailItem(
                  label: 'Management',
                  value: c.management,
                ),
              ],
              if (c.learningPoint != null && c.learningPoint.toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                _DetailItem(
                  label: 'Learning Point',
                  value: c.learningPoint,
                ),
              ],
            ],
          ),
        ),
        if (c.keywords.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
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
                const Row(
                  children: [
                    Icon(
                      Icons.label_outline,
                      color: Color(0xFF0B5FFF),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Keywords',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: c.keywords
                      .map<Widget>(
                        (k) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
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
                              fontSize: 13,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1E293B),
            height: 1.5,
          ),
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
    return Container(
      color: const Color(0xFFF7F9FC),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Follow-ups Yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Track patient follow-up visits here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/cases/$caseId/followup'),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Follow-up',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B5FFF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
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
    return Container(
      color: const Color(0xFFF7F9FC),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Media Files',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add images, documents, or other media',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/cases/$caseId/media'),
              icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
              label: const Text(
                'Add Media',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B5FFF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
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
      return Container(
        color: const Color(0xFFF7F9FC),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Container(
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B5FFF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.assessment_outlined,
                                color: Color(0xFF0B5FFF),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Submit for Assessment',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Request consultant review',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: _selectedConsultant,
                          items: const [],
                          onChanged: (v) => setState(() => _selectedConsultant = v),
                          decoration: InputDecoration(
                            labelText: 'Select Consultant',
                            labelStyle: const TextStyle(
                              color: Color(0xFF64748B),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF0B5FFF),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedConsultant == null
                    ? null
                    : () async {
                        await ref
                            .read(assessmentMutationProvider.notifier)
                            .submit(widget.caseId, _selectedConsultant!);
                      },
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text(
                  'Submit for Assessment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B5FFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey[300],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      color: const Color(0xFFF7F9FC),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Container(
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(assessment.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getStatusIcon(assessment.status),
                                  size: 16,
                                  color: _getStatusColor(assessment.status),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  assessment.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _getStatusColor(assessment.status),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (assessment.consultantComments != null &&
                          assessment.consultantComments.toString().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              color: Color(0xFF0B5FFF),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Consultant Comments',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          assessment.consultantComments,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF475569),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.isConsultant && assessment.status != 'completed') ...[
                  const SizedBox(height: 12),
                  Container(
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
                        const Text(
                          'Add Comments',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _comments,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Enter your assessment comments...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF0B5FFF),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.isConsultant && assessment.status != 'completed') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: mutation.isLoading
                    ? null
                    : () async {
                        await ref
                            .read(assessmentMutationProvider.notifier)
                            .complete(assessment.id, _comments.text);
                      },
                icon: mutation.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle, color: Colors.white),
                label: Text(
                  mutation.isLoading ? 'Processing...' : 'Mark Complete',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey[300],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'in_review':
        return const Color(0xFF0B5FFF);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_empty;
      case 'in_review':
        return Icons.rate_review;
      default:
        return Icons.info;
    }
  }
}
