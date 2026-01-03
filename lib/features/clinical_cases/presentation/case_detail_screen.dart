import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/shimmer_loading.dart';
import '../application/clinical_cases_controller.dart';
import '../application/assessment_controller.dart';
import '../domain/constants/anterior_segment_options.dart';
import '../domain/constants/fundus_options.dart';
import '../data/clinical_cases_repository.dart';
import '../data/assessment_repository.dart';
import '../../profile/application/profile_controller.dart';
import '../../auth/application/auth_controller.dart';
import '../../reviewer/application/reviewer_controller.dart';

class ClinicalCaseDetailScreen extends ConsumerWidget {
  const ClinicalCaseDetailScreen({
    super.key,
    required this.caseId,
    this.readOnly = false,
  });

  final String caseId;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final profileState = ref.watch(profileControllerProvider);
    final caseAsync = ref.watch(clinicalCaseDetailProvider(caseId));
    final recipientsAsync = ref.watch(caseAssessmentRecipientsProvider(caseId));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Case Detail'),
        actions: [
          caseAsync.maybeWhen(
            data: (c) {
              final authId = authState.session?.user.id;
              final designation = profileState.profile?.designation;
              final canScore =
                  designation == 'Consultant' &&
                  authId != null &&
                  authId != c.createdBy;
              final canEdit =
                  !readOnly && (c.status == 'draft' || c.status == 'submitted');
              final isRetinoblastoma = c.keywords.any(
                (k) => k.toLowerCase().contains('retinoblastoma'),
              );
              final isRop = c.keywords.any((k) => k.toLowerCase() == 'rop');
              final isLaser = c.keywords.any((k) => k.toLowerCase() == 'laser');
              final isUvea = c.keywords.any((k) => k.toLowerCase() == 'uvea');
              final canDelete =
                  !readOnly && authId != null && authId == c.createdBy;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canScore)
                    TextButton.icon(
                      onPressed: () => _showCaseScoreSheet(
                        context: context,
                        ref: ref,
                        caseId: c.id,
                        traineeId: c.createdBy,
                        initialRating: 0,
                        initialRemarks: '',
                      ),
                      icon: const Icon(Icons.star_rate),
                      label: const Text('Score Now'),
                    ),
                  if (canEdit)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => context.push(
                        isRetinoblastoma
                            ? '/cases/${c.id}/edit?type=retinoblastoma'
                            : isRop
                            ? '/cases/${c.id}/edit?type=rop'
                            : isLaser
                            ? '/cases/${c.id}/edit?type=laser'
                            : isUvea
                            ? '/cases/${c.id}/edit?type=uvea'
                            : '/cases/${c.id}/edit',
                      ),
                    ),
                  if (canDelete)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () =>
                          _showDeleteConfirmation(context, ref, c.id),
                      tooltip: 'Delete Case',
                    ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: caseAsync.when(
        data: (c) {
          final isUvea = c.keywords.any((k) => k.toLowerCase() == 'uvea');
          return DefaultTabController(
            length: 4,
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  child: const TabBar(
                    labelColor: Color(0xFF0B5FFF),
                    unselectedLabelColor: Color(0xFF64748B),
                    indicatorColor: Color(0xFF0B5FFF),
                    indicatorWeight: 3,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    tabs: [
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
                      _SummaryTab(
                        c: c,
                        isUvea: isUvea,
                        useRetinoblastomaLayout:
                            readOnly &&
                            (profileState.profile?.designation ==
                                'Consultant') &&
                            c.keywords.any(
                              (k) => k.toLowerCase().contains('retinoblastoma'),
                            ),
                        useRopLayout:
                            readOnly &&
                            (profileState.profile?.designation ==
                                'Consultant') &&
                            c.keywords.any((k) => k.toLowerCase() == 'rop'),
                      ),
                      _FollowupsTab(caseId: caseId, readOnly: readOnly),
                      _MediaTab(caseId: caseId, readOnly: readOnly),
                      recipientsAsync.when(
                        data: (recipients) => _AssessmentTab(
                          caseId: caseId,
                          recipients: recipients,
                          caseOwnerId: c.createdBy,
                          patientName: c.patientName,
                          uidNumber: c.uidNumber,
                          mrNumber: c.mrNumber,
                          caseStatus: c.status,
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
          child: CircularProgressIndicator(color: Color(0xFF0B5FFF)),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({
    required this.c,
    required this.isUvea,
    required this.useRetinoblastomaLayout,
    required this.useRopLayout,
  });
  final ClinicalCase c;
  final bool isUvea;
  final bool useRetinoblastomaLayout;
  final bool useRopLayout;

  @override
  Widget build(BuildContext context) {
    final examDate = c.dateOfExamination.toIso8601String().split('T').first;
    if (useRetinoblastomaLayout) {
      return _RetinoblastomaSummary(c: c);
    }
    if (useRopLayout) {
      return _RopSummary(c: c);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF3B82F6),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Patient Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _InfoRow(
                            label: 'Patient',
                            value: c.patientName,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _InfoRow(
                            label: 'Gender',
                            value: c.patientGender,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _InfoRow(label: 'UID', value: c.uidNumber),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _InfoRow(
                            label: 'Age',
                            value: c.patientAge.toString(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _InfoRow(
                            label: 'MR Number',
                            value: c.mrNumber,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _InfoRow(label: 'Exam Date', value: examDate),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF047857),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Status:',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF34D399)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF10B981).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              c.status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ..._ropMetaRows(c.fundus),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Chief Complaints Card
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF34D399)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.medical_information_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Chief Complaints',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'Complaint', value: c.chiefComplaint),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Duration',
                      value:
                          '${c.complaintDurationValue} ${c.complaintDurationUnit}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Systemic History Card
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF34D399)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.health_and_safety_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Systemic History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _formatSystemic(c.systemicHistory),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF475569),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Vision & IOP
        const Text(
          'Vision (BCVA) & IOP',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(60),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
            },
            border: TableBorder.all(color: Color(0xFFE2E8F0)),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'eye',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'RE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'LE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'BCVA',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(c.bcvaRe ?? '-'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(c.bcvaLe ?? '-'),
                  ),
                ],
              ),
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'IOP',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(c.iopRe?.toString() ?? '-'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(c.iopLe?.toString() ?? '-'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 32, color: Color(0xFFE2E8F0)),

        // Anterior Segment
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.remove_red_eye_outlined,
                color: Color(0xFF10B981),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Anterior Segment Examination',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildAnteriorSegmentCards(c.anteriorSegment),

        const Divider(height: 32, color: Color(0xFFE2E8F0)),

        // Fundus Examination
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.preview_outlined,
                color: Color(0xFFF59E0B),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Fundus Examination',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildFundusCards(c.fundus),

        if (_hasRopMeta(c.fundus)) ...[
          const Divider(height: 32, color: Color(0xFFE2E8F0)),
          const Text(
            'ROP Assessment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          ..._buildRopMetaRows(c.fundus),
        ],

        const Divider(height: 32, color: Color(0xFFE2E8F0)),

        // Diagnosis
        const Text(
          'Diagnosis',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          c.diagnosisOther == null || c.diagnosisOther!.isEmpty
              ? c.diagnosis
              : '${c.diagnosis} (${c.diagnosisOther})',
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),

        if (c.management != null && c.management!.isNotEmpty) ...[
          const Divider(height: 32, color: Color(0xFFE2E8F0)),
          const Text(
            'Management',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            c.management!,
            style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
        ],

        if (c.learningPoint != null && c.learningPoint!.isNotEmpty) ...[
          const Divider(height: 32, color: Color(0xFFE2E8F0)),
          const Text(
            'Learning Point',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            c.learningPoint!,
            style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
        ],

        if (c.keywords.isNotEmpty) ...[
          const Divider(height: 32, color: Color(0xFFE2E8F0)),
          const Text(
            'Keywords',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: c.keywords
                .map(
                  (k) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
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
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  String _formatSystemic(List<dynamic> items) {
    if (items.isEmpty) return 'Nil';
    return items.map((e) => e.toString()).join(', ');
  }

  Widget _buildAnteriorSegmentCards(Map<String, dynamic>? anterior) {
    if (anterior == null || anterior.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'No anterior segment data',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
        ),
      );
    }

    final reData = Map<String, dynamic>.from(anterior['RE'] as Map? ?? {});
    final leData = Map<String, dynamic>.from(anterior['LE'] as Map? ?? {});

    // List of findings to display (use your actual keys or section names)
    final findings = reData.keys.toSet().union(leData.keys.toSet()).toList();

    String getSelectedValue(Map<String, dynamic> data, String key) {
      final value = data[key];
      if (value is Map && value.containsKey('selected')) {
        final selected = value['selected'];
        if (selected is List && selected.isNotEmpty) {
          return selected.join(', ');
        } else if (selected is String && selected.isNotEmpty) {
          return selected;
        }
      }
      return '-';
    }

    String formatFinding(String finding) {
      // Replace underscores with spaces and capitalize first letter
      String formatted = finding.replaceAll('_', ' ');
      if (formatted.isNotEmpty) {
        formatted = formatted[0].toUpperCase() + formatted.substring(1);
      }
      return formatted;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(120),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
        },
        border: TableBorder.all(color: Color(0xFFE2E8F0)),
        children: [
          TableRow(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF34D399)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  'Finding',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  'RE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  'LE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          ...findings.asMap().entries.map((entry) {
            final index = entry.key;
            final finding = entry.value;
            return TableRow(
              decoration: BoxDecoration(
                color: index.isEven ? Colors.white : Color(0xFFF0FDF4),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    formatFinding(finding),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    getSelectedValue(reData, finding),
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    getSelectedValue(leData, finding),
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFundusCards(Map<String, dynamic>? fundus) {
    if (fundus == null || fundus.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'No fundus examination data',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
        ),
      );
    }

    final reData = Map<String, dynamic>.from(fundus['RE'] as Map? ?? {});
    final leData = Map<String, dynamic>.from(fundus['LE'] as Map? ?? {});

    final findings = reData.keys.toSet().union(leData.keys.toSet()).toList();

    String getSelectedValue(Map<String, dynamic> data, String key) {
      final value = data[key];
      if (value is Map && value.containsKey('selected')) {
        final selected = value['selected'];
        if (selected is List && selected.isNotEmpty) {
          return selected.join(', ');
        } else if (selected is String && selected.isNotEmpty) {
          return selected;
        }
      }
      return '-';
    }

    String formatFinding(String finding) {
      String formatted = finding.replaceAll('_', ' ');
      if (formatted.isNotEmpty) {
        formatted = formatted[0].toUpperCase() + formatted.substring(1);
      }
      return formatted;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(120),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
        },
        border: TableBorder.all(color: Color(0xFFE2E8F0)),
        children: [
          TableRow(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  'Finding',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  'RE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  'LE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          ...findings.asMap().entries.map((entry) {
            final index = entry.key;
            final finding = entry.value;
            return TableRow(
              decoration: BoxDecoration(
                color: index.isEven ? Colors.white : Color(0xFFFFFBEB),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    formatFinding(finding),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    getSelectedValue(reData, finding),
                    style: TextStyle(
                      color: Color(0xFFD97706),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    getSelectedValue(leData, finding),
                    style: TextStyle(
                      color: Color(0xFFD97706),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  List<Widget> _buildEyeFindings(
    Map<String, dynamic> eyeData,
    bool isAnterior,
  ) {
    final findings = <Widget>[];

    if (isAnterior) {
      for (final section in anteriorSegmentSections) {
        final sectionData = _coerceSection(eyeData[section.key]);
        final summary = _formatSection(sectionData);

        if (summary.isNotEmpty) {
          // Check if finding is normal
          final isNormal =
              summary.toLowerCase().contains('normal') ||
              summary.toLowerCase() == 'clear' ||
              summary.toLowerCase().contains('full and free');

          findings.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      section.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      summary,
                      style: TextStyle(
                        fontSize: 11,
                        color: isNormal
                            ? const Color(0xFF10B981)
                            : const Color(0xFF1E293B),
                        fontWeight: isNormal
                            ? FontWeight.w500
                            : FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } else {
      for (final section in fundusSections) {
        final sectionData = _coerceSection(eyeData[section.key]);
        final summary = _formatSection(sectionData);

        if (summary.isNotEmpty) {
          // Check if finding is normal
          final isNormal =
              summary.toLowerCase().contains('normal') ||
              summary.toLowerCase() == 'clear' ||
              summary.toLowerCase().contains('full and free');

          findings.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      section.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      summary,
                      style: TextStyle(
                        fontSize: 11,
                        color: isNormal
                            ? const Color(0xFF10B981)
                            : const Color(0xFF1E293B),
                        fontWeight: isNormal
                            ? FontWeight.w500
                            : FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    final remarks = (eyeData['remarks'] as String?) ?? '';
    if (remarks.trim().isNotEmpty) {
      findings.add(
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7).withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.note_outlined,
                size: 14,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  remarks,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF92400E),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (findings.isEmpty) {
      findings.add(
        const Center(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'No findings recorded',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    return findings;
  }

  String _formatAnterior(Map<String, dynamic>? anterior) {
    if (anterior == null || anterior.isEmpty) return '-';
    final lines = <String>[];
    final topRemarks = (anterior['remarks'] as String?) ?? '';
    for (final eyeKey in ['RE', 'LE']) {
      final eye = Map<String, dynamic>.from(anterior[eyeKey] as Map? ?? {});
      for (final section in anteriorSegmentSections) {
        final sectionData = _coerceSection(eye[section.key]);
        final summary = _formatSection(sectionData);
        if (summary.isNotEmpty) {
          lines.add('$eyeKey ${section.label}: $summary');
        }
      }
      final remarks = (eye['remarks'] as String?) ?? '';
      if (remarks.trim().isNotEmpty) {
        lines.add('$eyeKey Remarks: $remarks');
      }
    }
    if (topRemarks.trim().isNotEmpty) {
      lines.add('Remarks: $topRemarks');
    }
    if (lines.isEmpty) return '-';
    return lines.join('\n');
  }

  _Section? _buildLaserSection(Map<String, dynamic>? anterior) {
    if (anterior == null || anterior.isEmpty) return null;
    final laser = Map<String, dynamic>.from(anterior['laser'] as Map? ?? {});
    if (laser.isEmpty) return null;
    final bcva = Map<String, dynamic>.from(laser['bcva_pre'] as Map? ?? {});
    final diagnosis = Map<String, dynamic>.from(
      laser['diagnosis'] as Map? ?? {},
    );
    final laserType = Map<String, dynamic>.from(
      laser['laser_type'] as Map? ?? {},
    );
    final params = Map<String, dynamic>.from(laser['parameters'] as Map? ?? {});

    String eyeVal(Map<String, dynamic> map, String eye) {
      final value = map[eye];
      if (value == null) return '-';
      final text = value.toString().trim();
      return text.isEmpty ? '-' : text;
    }

    final paramsByEye = params.containsKey('RE') || params.containsKey('LE');

    String paramVal(String key) {
      final value =
          params[key] ??
          (key == 'power_mw' ? params['power'] : null) ??
          (key == 'duration_ms' ? params['duration'] : null) ??
          (key == 'spot_size_um' ? params['spot_size'] : null);
      if (value == null) return '-';
      final text = value.toString().trim();
      return text.isEmpty ? '-' : text;
    }

    String paramEyeVal(String eye, String key) {
      final eyeMap = Map<String, dynamic>.from(params[eye] as Map? ?? {});
      final value =
          eyeMap[key] ??
          (key == 'power_mw' ? eyeMap['power'] : null) ??
          (key == 'duration_ms' ? eyeMap['duration'] : null) ??
          (key == 'spot_size_um' ? eyeMap['spot_size'] : null);
      if (value == null) return '-';
      final text = value.toString().trim();
      return text.isEmpty ? '-' : text;
    }

    final hasParams = paramsByEye
        ? (() {
            final re = Map<String, dynamic>.from(params['RE'] as Map? ?? {});
            final le = Map<String, dynamic>.from(params['LE'] as Map? ?? {});
            return re.values.any(
                  (v) => v != null && v.toString().trim().isNotEmpty,
                ) ||
                le.values.any(
                  (v) => v != null && v.toString().trim().isNotEmpty,
                );
          })()
        : params.values.any((v) => v != null && v.toString().trim().isNotEmpty);

    return _Section(
      title: 'Laser Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EyePairRow(
            label: 'BCVA (pre-laser)',
            right: eyeVal(bcva, 'RE'),
            left: eyeVal(bcva, 'LE'),
          ),
          const SizedBox(height: 8),
          _EyePairRow(
            label: 'Diagnosis',
            right: eyeVal(diagnosis, 'RE'),
            left: eyeVal(diagnosis, 'LE'),
          ),
          const SizedBox(height: 8),
          _EyePairRow(
            label: 'Laser type',
            right: eyeVal(laserType, 'RE'),
            left: eyeVal(laserType, 'LE'),
          ),
          if (hasParams) ...[
            const SizedBox(height: 8),
            if (paramsByEye) ...[
              _EyePairRow(
                label: 'Power (mW)',
                right: paramEyeVal('RE', 'power_mw'),
                left: paramEyeVal('LE', 'power_mw'),
              ),
              _EyePairRow(
                label: 'Duration (ms)',
                right: paramEyeVal('RE', 'duration_ms'),
                left: paramEyeVal('LE', 'duration_ms'),
              ),
              _EyePairRow(
                label: 'Interval',
                right: paramEyeVal('RE', 'interval'),
                left: paramEyeVal('LE', 'interval'),
              ),
              _EyePairRow(
                label: 'Spot size (um)',
                right: paramEyeVal('RE', 'spot_size_um'),
                left: paramEyeVal('LE', 'spot_size_um'),
              ),
              _EyePairRow(
                label: 'Pattern',
                right: paramEyeVal('RE', 'pattern'),
                left: paramEyeVal('LE', 'pattern'),
              ),
              _EyePairRow(
                label: 'Spot spacing',
                right: paramEyeVal('RE', 'spot_spacing'),
                left: paramEyeVal('LE', 'spot_spacing'),
              ),
              _EyePairRow(
                label: 'Burn intensity',
                right: paramEyeVal('RE', 'burn_intensity'),
                left: paramEyeVal('LE', 'burn_intensity'),
              ),
            ] else ...[
              _InfoRow(label: 'Power (mW)', value: paramVal('power_mw')),
              _InfoRow(label: 'Duration (ms)', value: paramVal('duration_ms')),
              _InfoRow(label: 'Interval', value: paramVal('interval')),
              _InfoRow(
                label: 'Spot size (um)',
                value: paramVal('spot_size_um'),
              ),
              _InfoRow(label: 'Pattern', value: paramVal('pattern')),
              _InfoRow(label: 'Spot spacing', value: paramVal('spot_spacing')),
              _InfoRow(
                label: 'Burn intensity',
                value: paramVal('burn_intensity'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatFundus(Map<String, dynamic>? fundus, {bool isUvea = false}) {
    if (isUvea) {
      return _formatUveaFundus(fundus);
    }
    if (fundus == null || fundus.isEmpty) return '-';
    if (fundus.containsKey('RE') || fundus.containsKey('LE')) {
      final lines = <String>[];
      for (final eyeKey in ['RE', 'LE']) {
        final eye = Map<String, dynamic>.from(fundus[eyeKey] as Map? ?? {});
        for (final section in fundusSections) {
          final sectionData = _coerceSection(eye[section.key]);
          final summary = _formatSection(sectionData);
          if (summary.isNotEmpty) {
            lines.add('$eyeKey ${section.label}: $summary');
          }
        }
        final remarks = (eye['remarks'] as String?) ?? '';
        if (remarks.trim().isNotEmpty) {
          lines.add('$eyeKey Remarks: $remarks');
        }
      }
      return lines.join('\n');
    }
    final lines = <String>[];
    for (final section in fundusSections) {
      final sectionData = _coerceSection(fundus[section.key]);
      final summary = _formatSection(sectionData);
      if (summary.isNotEmpty) {
        lines.add('${section.label}: $summary');
      }
    }
    final remarks = (fundus['remarks'] as String?) ?? '';
    if (remarks.trim().isNotEmpty) {
      lines.add('Remarks: $remarks');
    }
    return lines.join('\n');
  }

  String _formatUveaAnterior(Map<String, dynamic>? anterior) {
    if (anterior == null || anterior.isEmpty) return '-';
    final uvea = Map<String, dynamic>.from(anterior['uvea'] as Map? ?? {});
    if (uvea.isEmpty) return '-';
    final lines = <String>[];
    for (final eyeKey in ['RE', 'LE']) {
      final eye = Map<String, dynamic>.from(uvea[eyeKey] as Map? ?? {});
      if (eye.isEmpty) continue;
      final conjunctiva = _formatOtherValue(
        eye['conjunctiva'],
        eye['conjunctiva_other'],
      );
      if (conjunctiva.isNotEmpty) {
        lines.add('$eyeKey Conjunctiva: $conjunctiva');
      }
      final corneaParts = <String>[];
      final keratitis = _boolLabel(eye['corneal_keratitis']);
      if (keratitis.isNotEmpty) {
        corneaParts.add('Keratitis $keratitis');
      }
      final kpsType = _stringValue(eye['kps_type']);
      final kpsDistribution = _stringValue(eye['kps_distribution']);
      if (kpsType.isNotEmpty || kpsDistribution.isNotEmpty) {
        final kps = [
          if (kpsType.isNotEmpty) kpsType,
          if (kpsDistribution.isNotEmpty) kpsDistribution,
        ].join(', ');
        corneaParts.add('KPs: $kps');
      }
      if (corneaParts.isNotEmpty) {
        lines.add('$eyeKey Cornea: ${corneaParts.join('; ')}');
      }
      final acCells = _stringValue(eye['ac_cells']);
      if (acCells.isNotEmpty) {
        lines.add('$eyeKey AC cells: $acCells');
      }
      final flare = _stringValue(eye['flare']);
      if (flare.isNotEmpty) {
        lines.add('$eyeKey Flare: $flare');
      }
      final fm = _boolLabel(eye['fm']);
      if (fm.isNotEmpty) {
        lines.add('$eyeKey FM: $fm');
      }
      final hypopyon = _boolLabel(eye['hypopyon']);
      if (hypopyon.isNotEmpty) {
        final height = _stringValue(eye['hypopyon_height_mm']);
        final suffix = height.isNotEmpty ? ' (${height} mm)' : '';
        lines.add('$eyeKey Hypopyon: $hypopyon$suffix');
      }
      final irisParts = <String>[];
      final nodules = _formatOtherValue(
        eye['iris_nodules'],
        eye['iris_nodules_other'],
      );
      if (nodules.isNotEmpty) {
        irisParts.add('Nodules: $nodules');
      }
      final synechiae = _stringValue(eye['iris_synechiae']);
      if (synechiae.isNotEmpty) {
        irisParts.add('Synechiae: $synechiae');
      }
      final rubeosis = _boolLabel(eye['iris_rubeosis']);
      if (rubeosis.isNotEmpty) {
        irisParts.add('Rubeosis: $rubeosis');
      }
      if (irisParts.isNotEmpty) {
        lines.add('$eyeKey Iris: ${irisParts.join('; ')}');
      }
      final glaucoma = _formatOtherValue(
        eye['glaucoma'],
        eye['glaucoma_other'],
      );
      if (glaucoma.isNotEmpty) {
        lines.add('$eyeKey Glaucoma: $glaucoma');
      }
      final lensStatus = _stringValue(eye['lens_status']);
      if (lensStatus.isNotEmpty) {
        lines.add('$eyeKey Lens status: $lensStatus');
      }
    }
    if (lines.isEmpty) return '-';
    return lines.join('\n');
  }

  String _formatUveaFundus(Map<String, dynamic>? fundus) {
    if (fundus == null || fundus.isEmpty) return '-';
    final uvea = Map<String, dynamic>.from(fundus['uvea'] as Map? ?? {});
    if (uvea.isEmpty) return '-';
    final lines = <String>[];
    for (final eyeKey in ['RE', 'LE']) {
      final eye = Map<String, dynamic>.from(uvea[eyeKey] as Map? ?? {});
      if (eye.isEmpty) continue;
      final avf = _stringValue(eye['avf_vitreous']);
      if (avf.isNotEmpty) {
        lines.add('$eyeKey AVF/Vitreous opacities: $avf');
      }
      final snowballs = _presenceLabel(eye['media_snowballs']);
      if (snowballs.isNotEmpty) {
        lines.add('$eyeKey Snowballs: $snowballs');
      }
      final opticDisc = _stringValue(eye['optic_disc']);
      if (opticDisc.isNotEmpty) {
        lines.add('$eyeKey Optic disc: $opticDisc');
      }
      final vessels = _stringValue(eye['vessels']);
      final vesselsType = _stringValue(eye['vessels_type']);
      final vesselText = [
        if (vessels.isNotEmpty) vessels,
        if (vesselsType.isNotEmpty) '($vesselsType)',
      ].join(' ');
      if (vesselText.trim().isNotEmpty) {
        lines.add('$eyeKey Vessels: $vesselText');
      }
      final backgroundParts = <String>[];
      final retinitis = _stringValue(eye['background_retinitis']);
      if (retinitis.isNotEmpty) {
        backgroundParts.add('Retinitis: $retinitis');
      }
      final choroiditis = _stringValue(eye['background_choroiditis']);
      if (choroiditis.isNotEmpty) {
        backgroundParts.add('Choroiditis: $choroiditis');
      }
      final vasculitis = _stringValue(eye['background_vasculitis']);
      if (vasculitis.isNotEmpty) {
        backgroundParts.add('Vasculitis: $vasculitis');
      }
      final snowbanking = _boolLabel(eye['background_snowbanking']);
      if (snowbanking.isNotEmpty) {
        backgroundParts.add('Snowbanking: $snowbanking');
      }
      final snowballing = _boolLabel(eye['background_snowballing']);
      if (snowballing.isNotEmpty) {
        backgroundParts.add('Snowballing: $snowballing');
      }
      final exudative = _boolLabel(eye['background_exudative_rd']);
      if (exudative.isNotEmpty) {
        backgroundParts.add('Exudative RD: $exudative');
      }
      final backgroundOther = _stringValue(eye['background_other']);
      if (backgroundOther.isNotEmpty) {
        backgroundParts.add('Other: $backgroundOther');
      }
      if (backgroundParts.isNotEmpty) {
        lines.add('$eyeKey Background: ${backgroundParts.join('; ')}');
      }
      final maculaParts = <String>[];
      final cme = _boolLabel(eye['macula_cme']);
      if (cme.isNotEmpty) {
        maculaParts.add('Cystoid macular edema: $cme');
      }
      final exudates = _boolLabel(eye['macula_exudates']);
      if (exudates.isNotEmpty) {
        maculaParts.add('Exudates: $exudates');
      }
      final maculaOther = _stringValue(eye['macula_other']);
      if (maculaOther.isNotEmpty) {
        maculaParts.add('Other: $maculaOther');
      }
      if (maculaParts.isNotEmpty) {
        lines.add('$eyeKey Macula: ${maculaParts.join('; ')}');
      }
      final extraNotes = _stringValue(eye['extra_notes']);
      if (extraNotes.isNotEmpty) {
        lines.add('$eyeKey Extra notes: $extraNotes');
      }
    }
    if (lines.isEmpty) return '-';
    return lines.join('\n');
  }

  String _formatUveaLocation(Map<String, dynamic>? fundus) {
    if (fundus == null || fundus.isEmpty) return '-';
    final locations = Map<String, dynamic>.from(
      fundus['uvea_location'] as Map? ?? {},
    );
    if (locations.isEmpty) return '-';
    final lines = <String>[];
    for (final eyeKey in ['RE', 'LE']) {
      final value = _stringValue(locations[eyeKey]);
      if (value.isNotEmpty) {
        lines.add('$eyeKey: $value');
      }
    }
    if (lines.isEmpty) return '-';
    return lines.join('\n');
  }

  String _stringValue(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  String _formatOtherValue(dynamic value, dynamic other) {
    final text = _stringValue(value);
    if (text.isEmpty) return '';
    if (text == 'Other') {
      final otherText = _stringValue(other);
      return otherText.isNotEmpty ? 'Other: $otherText' : 'Other';
    }
    return text;
  }

  String _boolLabel(dynamic value) {
    if (value == true) return 'Yes';
    if (value == false) return 'No';
    return '';
  }

  String _presenceLabel(dynamic value) {
    if (value == true) return 'Present';
    if (value == false) return 'Absent';
    return '';
  }

  bool _hasRopMeta(Map<String, dynamic>? fundus) {
    if (fundus == null || fundus.isEmpty) return false;
    return fundus['rop_meta'] is Map;
  }

  List<Widget> _ropMetaRows(Map<String, dynamic>? fundus) {
    final rows = <Widget>[];
    if (fundus == null || fundus.isEmpty) return rows;
    final meta = Map<String, dynamic>.from(fundus['rop_meta'] as Map? ?? {});
    if (meta.isEmpty) return rows;
    final gestational = meta['gestational_age']?.toString();
    final postConception = meta['post_conceptional_age']?.toString();
    if ((gestational ?? '').isNotEmpty) {
      rows.add(_InfoRow(label: 'Gestational age', value: '$gestational weeks'));
    }
    if ((postConception ?? '').isNotEmpty) {
      rows.add(
        _InfoRow(
          label: 'Post conceptional age',
          value: '$postConception weeks',
        ),
      );
    }
    return rows;
  }

  List<Widget> _buildRopMetaRows(Map<String, dynamic>? fundus) {
    final rows = <Widget>[];
    if (fundus == null || fundus.isEmpty) return rows;
    final meta = Map<String, dynamic>.from(fundus['rop_meta'] as Map? ?? {});
    if (meta.isEmpty) return rows;

    void addEyePair(String label, Map? values) {
      if (values == null) return;
      final right = values['RE']?.toString() ?? '-';
      final left = values['LE']?.toString() ?? '-';
      rows.add(_EyePairRow(label: label, right: right, left: left));
      rows.add(const SizedBox(height: 8));
    }

    addEyePair('Zone', meta['zone'] as Map?);
    addEyePair('Stage', meta['stage'] as Map?);
    addEyePair('Plus disease', _boolEyeMap(meta['plus_disease']));
    addEyePair('AGROP', _boolEyeMap(meta['agrop']));
    if (rows.isNotEmpty) {
      rows.removeLast();
    }
    return rows;
  }

  Map<String, String> _boolEyeMap(dynamic raw) {
    if (raw is! Map) return {'RE': '-', 'LE': '-'};
    return {
      'RE': raw['RE'] == true
          ? 'Yes'
          : raw['RE'] == false
          ? 'No'
          : '-',
      'LE': raw['LE'] == true
          ? 'Yes'
          : raw['LE'] == false
          ? 'No'
          : '-',
    };
  }

  String _formatSection(Map<String, dynamic> sectionData) {
    final selected =
        (sectionData['selected'] as List?)?.cast<String>() ?? <String>[];
    if (selected.isEmpty) return '';
    final descriptions = Map<String, dynamic>.from(
      sectionData['descriptions'] as Map? ?? {},
    );
    final other = (sectionData['other'] as String?) ?? '';
    final parts = <String>[];
    for (final option in selected) {
      if (option == 'Other') {
        if (other.trim().isNotEmpty) {
          parts.add('Other: $other');
        } else {
          parts.add('Other');
        }
        continue;
      }
      final desc = (descriptions[option] ?? '').toString().trim();
      if (desc.isNotEmpty) {
        parts.add('$option: $desc');
      } else {
        parts.add(option);
      }
    }
    return parts.join(', ');
  }

  Map<String, dynamic> _coerceSection(dynamic raw) {
    if (raw is Map && raw.containsKey('selected')) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is Map && raw.containsKey('status')) {
      final status = (raw['status'] as String?) ?? '';
      final notes = (raw['notes'] as String?) ?? '';
      if (status == 'abnormal' && notes.trim().isNotEmpty) {
        return {
          'selected': <String>['Other'],
          'descriptions': <String, String>{},
          'other': notes,
        };
      }
      if (status.isNotEmpty) {
        return {
          'selected': <String>['Normal'],
          'descriptions': <String, String>{},
          'other': '',
        };
      }
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return {
        'selected': <String>[raw],
        'descriptions': <String, String>{},
        'other': '',
      };
    }
    return {};
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '-' : value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _EyePairRow extends StatelessWidget {
  const _EyePairRow({
    required this.label,
    required this.right,
    required this.left,
  });

  final String label;
  final String right;
  final String left;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RE', style: labelStyle),
                  Text(right, style: valueStyle),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LE', style: labelStyle),
                  Text(left, style: valueStyle),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RetinoblastomaSummary extends StatelessWidget {
  const _RetinoblastomaSummary({required this.c});

  final ClinicalCase c;

  @override
  Widget build(BuildContext context) {
    final anterior = c.anteriorSegment ?? const <String, dynamic>{};
    final fundus = c.fundus ?? const <String, dynamic>{};
    final rb = Map<String, dynamic>.from(
      anterior['retinoblastoma'] as Map? ?? {},
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _CaseSectionCard(
          title: 'Patient Details',
          child: Column(
            children: [
              _InfoRow(label: 'Patient', value: c.patientName),
              _InfoRow(label: 'Age', value: c.patientAge.toString()),
              _InfoRow(label: 'UID', value: c.uidNumber),
              _InfoRow(label: 'MRN', value: c.mrNumber),
              _InfoRow(label: 'Gender', value: c.patientGender),
              _InfoRow(
                label: 'Exam Date',
                value: _formatExamDate(c.dateOfExamination),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _CaseSectionCard(
          title: 'Anterior Segment Remarks',
          child: Column(
            children: [
              _EyePairRow(
                label: 'Remarks',
                right: _eyeRemarks(anterior, 'RE'),
                left: _eyeRemarks(anterior, 'LE'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _CaseSectionCard(
          title: 'Fundus Examination',
          child: Column(
            children: [
              _EyePairRow(
                label: 'Media',
                right: _selectedValue(fundus, 'RE', 'media'),
                left: _selectedValue(fundus, 'LE', 'media'),
              ),
              const SizedBox(height: 8),
              _EyePairRow(
                label: 'Optic disc',
                right: _selectedValue(fundus, 'RE', 'optic_disc'),
                left: _selectedValue(fundus, 'LE', 'optic_disc'),
              ),
              const SizedBox(height: 8),
              _EyePairRow(
                label: 'Vessels',
                right: _selectedValue(fundus, 'RE', 'vessels'),
                left: _selectedValue(fundus, 'LE', 'vessels'),
              ),
              const SizedBox(height: 8),
              _EyePairRow(
                label: 'Background',
                right: _selectedValue(fundus, 'RE', 'background_retina'),
                left: _selectedValue(fundus, 'LE', 'background_retina'),
              ),
              const SizedBox(height: 8),
              _EyePairRow(
                label: 'Macula',
                right: _selectedValue(fundus, 'RE', 'macula'),
                left: _selectedValue(fundus, 'LE', 'macula'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _CaseSectionCard(
          title: 'Retinoblastoma Details',
          child: Column(
            children: [
              _InfoRow(
                label: 'Vitreous seedings',
                value: _boolLabel(rb['vitreous_seedings'] as bool?),
              ),
              _InfoRow(
                label: 'Retinal detachment',
                value: _boolLabel(rb['retinal_detachment'] as bool?),
              ),
              _InfoRow(label: 'Group', value: rb['group']?.toString() ?? '-'),
              _InfoRow(
                label: 'Regression pattern',
                value: rb['regression_pattern']?.toString() ?? '-',
              ),
              _InfoRow(
                label: 'Treatment given',
                value: _joinList(rb['treatment_given']),
              ),
              if ((rb['treatment_other'] ?? '').toString().trim().isNotEmpty)
                _InfoRow(
                  label: 'Treatment (other)',
                  value: rb['treatment_other']?.toString() ?? '-',
                ),
              _InfoRow(
                label: 'No. of sittings',
                value: rb['sittings']?.toString() ?? '-',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _CaseSectionCard(
          title: 'Diagnosis & Remarks',
          child: Column(
            children: [
              _InfoRow(label: 'Diagnosis', value: c.diagnosis),
              _InfoRow(
                label: 'Remarks',
                value: (c.management ?? '').isEmpty ? '-' : c.management!,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RopSummary extends StatelessWidget {
  const _RopSummary({required this.c});

  final ClinicalCase c;

  @override
  Widget build(BuildContext context) {
    final anterior = c.anteriorSegment ?? const <String, dynamic>{};
    final fundus = c.fundus ?? const <String, dynamic>{};
    final ropMeta = Map<String, dynamic>.from(fundus['rop_meta'] as Map? ?? {});
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _CaseSectionCard(
          title: 'Patient Details',
          child: Column(
            children: [
              _InfoRow(label: 'Patient', value: c.patientName),
              _InfoRow(label: 'UID', value: c.uidNumber),
              _InfoRow(label: 'MRN', value: c.mrNumber),
              _InfoRow(label: 'Gender', value: c.patientGender),
              _InfoRow(
                label: 'Exam Date',
                value: _formatExamDate(c.dateOfExamination),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _CaseSectionCard(
          title: 'Anterior Segment',
          child: Column(
            children: [
              _EyePairRow(
                label: 'Pupil',
                right: _selectedValue(anterior, 'RE', 'pupil'),
                left: _selectedValue(anterior, 'LE', 'pupil'),
              ),
              const SizedBox(height: 8),
              _EyePairRow(
                label: 'Lens',
                right: _selectedValue(anterior, 'RE', 'lens'),
                left: _selectedValue(anterior, 'LE', 'lens'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _CaseSectionCard(
          title: 'Fundus Examination',
          child: Column(
            children: [
              _EyePairRow(
                label: 'Media',
                right: _selectedValue(fundus, 'RE', 'media'),
                left: _selectedValue(fundus, 'LE', 'media'),
              ),
              const SizedBox(height: 8),
              _EyePairRow(
                label: 'Optic disc',
                right: _selectedValue(fundus, 'RE', 'optic_disc'),
                left: _selectedValue(fundus, 'LE', 'optic_disc'),
              ),
              const SizedBox(height: 8),
              _EyePairRow(
                label: 'Vessels',
                right: _selectedValue(fundus, 'RE', 'vessels'),
                left: _selectedValue(fundus, 'LE', 'vessels'),
              ),
              const SizedBox(height: 8),
              _EyePairRow(
                label: 'Background',
                right: _selectedValue(fundus, 'RE', 'background_retina'),
                left: _selectedValue(fundus, 'LE', 'background_retina'),
              ),
              const SizedBox(height: 8),
              _EyePairRow(
                label: 'Macula',
                right: _selectedValue(fundus, 'RE', 'macula'),
                left: _selectedValue(fundus, 'LE', 'macula'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _CaseSectionCard(
          title: 'ROP Assessment',
          child: Column(
            children: [
              _InfoRow(
                label: 'Gestational age',
                value: ropMeta['gestational_age']?.toString() ?? '-',
              ),
              _InfoRow(
                label: 'Post conceptional age',
                value: ropMeta['post_conceptional_age']?.toString() ?? '-',
              ),
              const SizedBox(height: 8),
              _EyePairRow(
                label: 'Zone',
                right: _eyeMapValue(ropMeta['zone'], 'RE'),
                left: _eyeMapValue(ropMeta['zone'], 'LE'),
              ),
              const SizedBox(height: 8),
              _EyePairRow(
                label: 'Stage',
                right: _eyeMapValue(ropMeta['stage'], 'RE'),
                left: _eyeMapValue(ropMeta['stage'], 'LE'),
              ),
              const SizedBox(height: 8),
              _EyePairRow(
                label: 'Plus disease',
                right: _boolLabel(_eyeMapBool(ropMeta['plus_disease'], 'RE')),
                left: _boolLabel(_eyeMapBool(ropMeta['plus_disease'], 'LE')),
              ),
              const SizedBox(height: 8),
              _EyePairRow(
                label: 'AGROP',
                right: _boolLabel(_eyeMapBool(ropMeta['agrop'], 'RE')),
                left: _boolLabel(_eyeMapBool(ropMeta['agrop'], 'LE')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _CaseSectionCard(
          title: 'Diagnosis & Remarks',
          child: Column(
            children: [
              _InfoRow(label: 'Diagnosis', value: c.diagnosis),
              _InfoRow(
                label: 'Remarks',
                value: (c.management ?? '').isEmpty ? '-' : c.management!,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatExamDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _selectedValue(Map<String, dynamic> payload, String eye, String key) {
  final eyeMap = Map<String, dynamic>.from(payload[eye] as Map? ?? {});
  final section = Map<String, dynamic>.from(eyeMap[key] as Map? ?? {});
  final selected = (section['selected'] as List?)?.cast<String>() ?? const [];
  if (selected.isEmpty) return '-';
  return selected.join(', ');
}

String _eyeRemarks(Map<String, dynamic> anterior, String eye) {
  final eyeMap = Map<String, dynamic>.from(anterior[eye] as Map? ?? {});
  final remarks = (eyeMap['remarks'] as String?) ?? '';
  return remarks.trim().isEmpty ? '-' : remarks.trim();
}

String _boolLabel(bool? value) {
  if (value == null) return '-';
  return value ? 'Yes' : 'No';
}

String _joinList(dynamic value) {
  if (value is List) {
    final items = value
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    if (items.isEmpty) return '-';
    return items.join(', ');
  }
  return '-';
}

String _eyeMapValue(dynamic data, String eye) {
  if (data is Map) {
    final value = data[eye];
    if (value == null || value.toString().trim().isEmpty) return '-';
    return value.toString();
  }
  return '-';
}

bool? _eyeMapBool(dynamic data, String eye) {
  if (data is Map) {
    return data[eye] as bool?;
  }
  return null;
}

class _CaseSectionCard extends StatelessWidget {
  const _CaseSectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _FollowupsTab extends ConsumerWidget {
  const _FollowupsTab({required this.caseId, required this.readOnly});
  final String caseId;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followupsAsync = ref.watch(caseFollowupsProvider(caseId));
    return followupsAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return _EmptyState(
            icon: Icons.event_note_outlined,
            title: 'No Follow-ups Yet',
            subtitle: 'Track patient follow-up visits here',
            actionLabel: readOnly ? null : 'Add Follow-up',
            onAction: readOnly
                ? null
                : () => context.push('/cases/$caseId/followup'),
          );
        }
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final f = list[index];
                  final date = f.dateOfExamination
                      .toIso8601String()
                      .split('T')
                      .first;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Follow-up ${f.followupIndex}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Text(date),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Interval: ${f.intervalDays} days'),
                          if (f.management != null &&
                              f.management!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text('Management: ${f.management}'),
                          ],
                          const SizedBox(height: 8),
                          if (!readOnly)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => context.push(
                                  '/cases/$caseId/followup/${f.id}',
                                ),
                                child: const Text('Edit'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (!readOnly)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/cases/$caseId/followup'),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Add Follow-up'),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load follow-ups: $e')),
    );
  }
}

class _MediaTab extends ConsumerWidget {
  const _MediaTab({required this.caseId, required this.readOnly});
  final String caseId;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(caseMediaProvider(caseId));
    return mediaAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return _EmptyState(
            icon: Icons.photo_library_outlined,
            title: 'No Media Files',
            subtitle: 'Add images or videos',
            actionLabel: 'Add Media',
            onAction: () => context.push('/cases/$caseId/media'),
          );
        }

        // Group by category/eye based on naming convention
        // Categories might include "fundus_re", "anterior_re", etc.
        final reMedia = list
            .where(
              (m) =>
                  m.category.toLowerCase().contains('_re') ||
                  m.category.toLowerCase().endsWith('re'),
            )
            .toList();
        final leMedia = list
            .where(
              (m) =>
                  m.category.toLowerCase().contains('_le') ||
                  m.category.toLowerCase().endsWith('le'),
            )
            .toList();
        final otherMedia = list
            .where(
              (m) =>
                  !m.category.toLowerCase().contains('_re') &&
                  !m.category.toLowerCase().endsWith('re') &&
                  !m.category.toLowerCase().contains('_le') &&
                  !m.category.toLowerCase().endsWith('le'),
            )
            .toList();

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (reMedia.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'RIGHT EYE',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: reMedia.length,
                      itemBuilder: (context, index) =>
                          _MediaTile(item: reMedia[index]),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (leMedia.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'LEFT EYE',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: leMedia.length,
                      itemBuilder: (context, index) =>
                          _MediaTile(item: leMedia[index]),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (otherMedia.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF64748B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'OTHER MEDIA',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: otherMedia.length,
                      itemBuilder: (context, index) =>
                          _MediaTile(item: otherMedia[index]),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/cases/$caseId/media'),
                  icon: const Icon(
                    Icons.add_photo_alternate,
                    color: Colors.white,
                  ),
                  label: const Text('Add Media'),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load media: $e')),
    );
  }
}

class _MediaTile extends ConsumerWidget {
  const _MediaTile({required this.item});

  final CaseMediaItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(clinicalCasesRepositoryProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FutureBuilder<String>(
                future: repo.getSignedUrl(item.storagePath),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  final url = snapshot.data!;
                  if (item.mediaType == 'video') {
                    return InkWell(
                      onTap: () => launchUrl(Uri.parse(url)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.play_circle_fill, size: 48),
                        ),
                      ),
                    );
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.category.replaceAll('_', ' '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            if (item.note != null && item.note!.isNotEmpty)
              Text(
                item.note!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

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
                  Icon(icon, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(actionLabel!),
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
    required this.recipients,
    required this.caseOwnerId,
    required this.patientName,
    required this.uidNumber,
    required this.mrNumber,
    required this.caseStatus,
  });
  final String caseId;
  final List<AssessmentRecipient> recipients;
  final String caseOwnerId;
  final String patientName;
  final String uidNumber;
  final String mrNumber;
  final String caseStatus;

  @override
  ConsumerState<_AssessmentTab> createState() => _AssessmentTabState();
}

class _AssessmentTabState extends ConsumerState<_AssessmentTab> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedRecipients = {};
  bool _seededSelection = false;

  @override
  Widget build(BuildContext context) {
    final mutation = ref.watch(assessmentMutationProvider);
    final authState = ref.watch(authControllerProvider);
    final profileState = ref.watch(profileControllerProvider);
    final myAssessmentAsync = ref.watch(
      reviewerCaseAssessmentProvider(widget.caseId),
    );
    final doctorsAsync = ref.watch(assessmentDoctorsProvider);
    final authId = authState.session?.user.id;
    final isOwner = authId != null && authId == widget.caseOwnerId;
    final designation = profileState.profile?.designation;
    final isConsultant = designation == 'Consultant';
    final hasReviewerAccess = designation == 'Reviewer' || isConsultant;

    if (!_seededSelection && widget.recipients.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedRecipients
            ..clear()
            ..addAll(widget.recipients.map((r) => r.recipientId));
          _seededSelection = true;
        });
      });
    }

    final isAssignedReviewer = widget.recipients.any(
      (r) => r.recipientId == authId && r.canReview,
    );
    final canScore =
        (isConsultant && authId != null && authId != widget.caseOwnerId) ||
        (designation == 'Reviewer' && isAssignedReviewer);

    return Container(
      color: const Color(0xFFF7F9FC),
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StatusPill(status: widget.caseStatus),
                      const SizedBox(width: 8),
                      const Text(
                        'Assessment',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (widget.recipients.isEmpty)
                    const Text(
                      'No assessment submitted yet.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Submitted to',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.recipients
                              .map(
                                (r) => Chip(
                                  label: Text('${r.name} (${r.designation})'),
                                  avatar: r.canReview
                                      ? const Icon(
                                          Icons.verified,
                                          size: 16,
                                          color: Color(0xFF0B5FFF),
                                        )
                                      : null,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (isOwner) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select doctors for assessment',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search doctors by name or designation',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    doctorsAsync.when(
                      data: (list) {
                        final query = _searchController.text
                            .trim()
                            .toLowerCase();
                        final filtered = query.isEmpty
                            ? list
                            : list.where((p) {
                                final centre = p.aravindCentre ?? p.centre;
                                return p.name.toLowerCase().contains(query) ||
                                    p.designation.toLowerCase().contains(
                                      query,
                                    ) ||
                                    centre.toLowerCase().contains(query);
                              }).toList();
                        if (filtered.isEmpty) {
                          return const Text('No doctors found.');
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final doctor = filtered[index];
                            final isSelected = _selectedRecipients.contains(
                              doctor.id,
                            );
                            return CheckboxListTile(
                              value: isSelected,
                              title: Text(doctor.name),
                              subtitle: Text(
                                '${doctor.designation} | ${doctor.aravindCentre ?? doctor.centre}',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedRecipients.add(doctor.id);
                                  } else {
                                    _selectedRecipients.remove(doctor.id);
                                  }
                                });
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedRecipients.isEmpty || mutation.isLoading
                    ? null
                    : () async {
                        await ref
                            .read(assessmentMutationProvider.notifier)
                            .submitRecipients(
                              widget.caseId,
                              _selectedRecipients.toList(),
                            );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Assessment submitted'),
                            ),
                          );
                        }
                        ref.invalidate(
                          caseAssessmentRecipientsProvider(widget.caseId),
                        );
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
                    : const Icon(Icons.send, color: Colors.white),
                label: Text(
                  mutation.isLoading ? 'Submitting...' : 'Submit Assessment',
                ),
              ),
            ),
          ],
          if (!isOwner && widget.recipients.isNotEmpty && !canScore) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.visibility, color: Color(0xFF64748B)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You have view access to this case. Only assigned consultants can submit scores.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (hasReviewerAccess && canScore) ...[
            const SizedBox(height: 12),
            myAssessmentAsync.when(
              data: (assessment) {
                final score = assessment?.score ?? 0;
                final remarks = assessment?.remarks ?? '';
                final hasScore = assessment?.score != null;
                return _ReviewerScoreCard(
                  score: score,
                  remarks: remarks,
                  onEdit: () => _showCaseScoreSheet(
                    context: context,
                    ref: ref,
                    caseId: widget.caseId,
                    traineeId: widget.caseOwnerId,
                    initialRating: score,
                    initialRemarks: remarks,
                  ),
                  hasScore: hasScore,
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Failed to load score: $e'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    Color color;
    switch (normalized) {
      case 'completed':
        color = const Color(0xFF10B981);
        break;
      case 'submitted':
        color = const Color(0xFF0B5FFF);
        break;
      case 'in_review':
        color = const Color(0xFFF59E0B);
        break;
      default:
        color = const Color(0xFF64748B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        normalized.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// --------------------------------------------------
// Delete Case Confirmation Dialog
// --------------------------------------------------
void _showDeleteConfirmation(
  BuildContext context,
  WidgetRef ref,
  String caseId,
) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text(
              'Delete Case',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this case? This action cannot be undone.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'No',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await ref
                    .read(clinicalCasesRepositoryProvider)
                    .deleteCase(caseId);

                // Refresh lists
                ref.invalidate(clinicalCaseListProvider);
                ref.invalidate(clinicalCaseListByKeywordProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Case deleted successfully'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete case: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Yes, Delete',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    },
  );
}

// --------------------------------------------------
// Reviewer Score Card
// --------------------------------------------------
class _ReviewerScoreCard extends StatelessWidget {
  const _ReviewerScoreCard({
    required this.score,
    required this.remarks,
    required this.onEdit,
    required this.hasScore,
  });

  final int score;
  final String remarks;
  final VoidCallback onEdit;
  final bool hasScore;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Your Score',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text(hasScore ? 'Edit Score' : 'Score Now'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _RatingStars(rating: score),
            if (remarks.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                remarks,
                style: const TextStyle(color: Color(0xFF475569), height: 1.4),
              ),
            ],
            if (!hasScore)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'No score submitted yet.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------
// Rating Stars Widget
// --------------------------------------------------
class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final isSelected = rating >= index + 1;
        return Icon(
          isSelected ? Icons.star : Icons.star_border,
          color: Colors.amber[600],
        );
      }),
    );
  }
}

// --------------------------------------------------
// Show Case Score Bottom Sheet
// --------------------------------------------------
Future<void> _showCaseScoreSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String caseId,
  required String traineeId,
  int initialRating = 0,
  String initialRemarks = '',
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return _CaseScoreSheet(
        caseId: caseId,
        traineeId: traineeId,
        initialRating: initialRating,
        initialRemarks: initialRemarks,
      );
    },
  );
}

// --------------------------------------------------
// Case Score Sheet
// --------------------------------------------------
class _CaseScoreSheet extends ConsumerStatefulWidget {
  const _CaseScoreSheet({
    required this.caseId,
    required this.traineeId,
    required this.initialRating,
    required this.initialRemarks,
  });

  final String caseId;
  final String traineeId;
  final int initialRating;
  final String initialRemarks;

  @override
  ConsumerState<_CaseScoreSheet> createState() => _CaseScoreSheetState();
}

class _CaseScoreSheetState extends ConsumerState<_CaseScoreSheet> {
  final TextEditingController _remarksController = TextEditingController();
  int _rating = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating.clamp(0, 5);
    _remarksController.text = widget.initialRemarks;
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(reviewerMutationProvider.notifier)
          .submitClinicalCase(
            caseId: widget.caseId,
            traineeId: widget.traineeId,
            score: _rating,
            remarks: _remarksController.text.trim(),
          );

      if (!mounted) return;

      Navigator.pop(context);
      ref.invalidate(reviewerCaseAssessmentProvider(widget.caseId));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Score submitted')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit score: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score Case',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              'Rating (0–5)',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ...List.generate(5, (index) {
                  final isSelected = _rating >= index + 1;
                  return IconButton(
                    onPressed: () => setState(() => _rating = index + 1),
                    icon: Icon(
                      isSelected ? Icons.star : Icons.star_border,
                      color: Colors.amber[600],
                    ),
                  );
                }),
                TextButton(
                  onPressed: _rating == 0
                      ? null
                      : () => setState(() => _rating = 0),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarksController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                hintText: 'Add remarks for this case',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
