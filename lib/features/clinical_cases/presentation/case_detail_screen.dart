import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../application/clinical_cases_controller.dart';
import '../application/assessment_controller.dart';
import '../domain/constants/anterior_segment_options.dart';
import '../domain/constants/fundus_options.dart';
import '../data/clinical_cases_repository.dart';
import '../../profile/application/profile_controller.dart';
import '../../auth/application/auth_controller.dart';

class ClinicalCaseDetailScreen extends ConsumerWidget {
  const ClinicalCaseDetailScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseAsync = ref.watch(clinicalCaseDetailProvider(caseId));
    final assessmentAsync = ref.watch(caseAssessmentProvider(caseId));
    final profileState = ref.watch(profileControllerProvider);
    final isConsultant = profileState.profile?.designation == 'Consultant';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Case Detail'),
        actions: [
          caseAsync.maybeWhen(
            data: (c) {
              final canEdit = c.status == 'draft' || c.status == 'submitted';
              if (!canEdit) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/cases/${c.id}/edit'),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: caseAsync.when(
        data: (c) {
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
  final ClinicalCase c;

  @override
  Widget build(BuildContext context) {
    final examDate = c.dateOfExamination.toIso8601String().split('T').first;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _StyledSection(
          title: 'Patient Information',
          icon: Icons.person_outline,
          children: [
            _StyledInfoRow(label: 'Patient', value: c.patientName),
            _StyledInfoRow(label: 'UID', value: c.uidNumber),
            _StyledInfoRow(label: 'MR Number', value: c.mrNumber),
            _StyledInfoRow(label: 'Gender', value: c.patientGender),
            _StyledInfoRow(label: 'Age', value: c.patientAge.toString()),
            _StyledInfoRow(label: 'Exam Date', value: examDate),
            _StyledInfoRow(label: 'Status', value: c.status),
          ],
        ),
        const SizedBox(height: 10),
        _StyledSection(
          title: 'Complaints',
          icon: Icons.medical_information_outlined,
          children: [
            _StyledInfoRow(label: 'Chief Complaint', value: c.chiefComplaint),
            _StyledInfoRow(
              label: 'Duration',
              value: '${c.complaintDurationValue} ${c.complaintDurationUnit}',
            ),
          ],
        ),
        const SizedBox(height: 10),
        _StyledSection(
          title: 'Systemic History',
          icon: Icons.history_outlined,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                _formatSystemic(c.systemicHistory),
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _VisionIopSection(
          bcvaRe: c.bcvaRe ?? '-',
          bcvaLe: c.bcvaLe ?? '-',
          iopRe: c.iopRe?.toString() ?? '-',
          iopLe: c.iopLe?.toString() ?? '-',
        ),
        const SizedBox(height: 10),
        _EyeSeparatedSection(
          title: 'Anterior Segment',
          data: c.anteriorSegment,
          isFundus: false,
        ),
        const SizedBox(height: 10),
        _EyeSeparatedSection(
          title: 'Fundus Examination',
          data: c.fundus,
          isFundus: true,
        ),
        const SizedBox(height: 10),
        _StyledSection(
          title: 'Diagnosis',
          icon: Icons.local_hospital_outlined,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                c.diagnosisOther == null || c.diagnosisOther!.isEmpty
                    ? c.diagnosis
                    : '${c.diagnosis} (${c.diagnosisOther})',
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
            ),
          ],
        ),
        if (c.management != null && c.management!.isNotEmpty) ...[
          const SizedBox(height: 10),
          _Section(
            title: 'Management',
            child: Text(
              c.management!,
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
            ),
          ),
        ],
        if (c.learningPoint != null && c.learningPoint!.isNotEmpty) ...[
          const SizedBox(height: 10),
          _Section(
            title: 'Learning Point',
            child: Text(
              c.learningPoint!,
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
            ),
          ),
        ],
        if (c.keywords.isNotEmpty) ...[
          const SizedBox(height: 10),
          _StyledSection(
            title: 'Keywords',
            icon: Icons.label_outline,
            children: [
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0B5FFF), Color(0xFF0EA5E9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0B5FFF).withOpacity(0.2),
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          k,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatSystemic(List<dynamic> items) {
    if (items.isEmpty) return 'Nil';
    return items.map((e) => e.toString()).join(', ');
  }

  String _formatAnterior(Map<String, dynamic>? anterior) {
    if (anterior == null || anterior.isEmpty) return '-';
    final lines = <String>[];
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
    return lines.join('\n');
  }

  String _formatFundus(Map<String, dynamic>? fundus) {
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

  String _formatSection(Map<String, dynamic> sectionData) {
    final selected =
        (sectionData['selected'] as List?)?.cast<String>() ?? <String>[];
    if (selected.isEmpty) return '';
    final descriptions =
        Map<String, dynamic>.from(sectionData['descriptions'] as Map? ?? {});
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

class _StyledSection extends StatelessWidget {
  const _StyledSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B5FFF), Color(0xFF0EA5E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) const SizedBox(height: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StyledInfoRow extends StatelessWidget {
  const _StyledInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0B5FFF),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisionIopSection extends StatelessWidget {
  const _VisionIopSection({
    required this.bcvaRe,
    required this.bcvaLe,
    required this.iopRe,
    required this.iopLe,
  });

  final String bcvaRe;
  final String bcvaLe;
  final String iopRe;
  final String iopLe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vision (BCVA) & IOP',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _VisionIopEyeCard(
                  eyeLabel: 'RE',
                  bcva: bcvaRe,
                  iop: iopRe,
                  isRight: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _VisionIopEyeCard(
                  eyeLabel: 'LE',
                  bcva: bcvaLe,
                  iop: iopLe,
                  isRight: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VisionIopEyeCard extends StatelessWidget {
  const _VisionIopEyeCard({
    required this.eyeLabel,
    required this.bcva,
    required this.iop,
    required this.isRight,
  });

  final String eyeLabel;
  final String bcva;
  final String iop;
  final bool isRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRight
              ? [const Color(0xFF0B5FFF).withOpacity(0.08), const Color(0xFF0EA5E9).withOpacity(0.05)]
              : [const Color(0xFF10B981).withOpacity(0.08), const Color(0xFF059669).withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRight
              ? const Color(0xFF0B5FFF).withOpacity(0.2)
              : const Color(0xFF10B981).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRight ? Icons.remove_red_eye : Icons.remove_red_eye_outlined,
                color: isRight ? const Color(0xFF0B5FFF) : const Color(0xFF10B981),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                eyeLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isRight ? const Color(0xFF0B5FFF) : const Color(0xFF10B981),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _VisionIopRow(label: 'BCVA', value: bcva),
          const SizedBox(height: 6),
          _VisionIopRow(label: 'IOP', value: iop),
        ],
      ),
    );
  }
}

class _VisionIopRow extends StatelessWidget {
  const _VisionIopRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}

class _EyeSeparatedSection extends StatelessWidget {
  const _EyeSeparatedSection({
    required this.title,
    required this.data,
    required this.isFundus,
  });

  final String title;
  final Map<String, dynamic>? data;
  final bool isFundus;

  @override
  Widget build(BuildContext context) {
    if (data == null || data!.isEmpty) {
      return _Section(
        title: title,
        child: const Text(
          '-',
          style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
      );
    }

    final reData = Map<String, dynamic>.from(data!['RE'] as Map? ?? {});
    final leData = Map<String, dynamic>.from(data!['LE'] as Map? ?? {});
    final sections = isFundus ? fundusSections : anteriorSegmentSections;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _EyeColumn(
                  eyeLabel: 'RE',
                  eyeData: reData,
                  sections: sections,
                  isRight: true,
                ),
              ),
              Container(
                width: 2,
                height: null,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0B5FFF).withOpacity(0.3),
                      const Color(0xFF0EA5E9).withOpacity(0.2),
                      const Color(0xFF0B5FFF).withOpacity(0.3),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Expanded(
                child: _EyeColumn(
                  eyeLabel: 'LE',
                  eyeData: leData,
                  sections: sections,
                  isRight: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EyeColumn extends StatelessWidget {
  const _EyeColumn({
    required this.eyeLabel,
    required this.eyeData,
    required this.sections,
    required this.isRight,
  });

  final String eyeLabel;
  final Map<String, dynamic> eyeData;
  final List<dynamic> sections;
  final bool isRight;

  @override
  Widget build(BuildContext context) {
    final findings = <Widget>[];

    for (final section in sections) {
      final sectionKey = section.key as String;
      final sectionLabel = section.label as String;
      final sectionData = _coerceSection(eyeData[sectionKey]);
      final summary = _formatSectionData(sectionData);

      if (summary.isNotEmpty) {
        findings.add(
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: isRight 
                  ? const Color(0xFF0B5FFF).withOpacity(0.03)
                  : const Color(0xFF10B981).withOpacity(0.03),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isRight
                    ? const Color(0xFF0B5FFF).withOpacity(0.1)
                    : const Color(0xFF10B981).withOpacity(0.1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    sectionLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isRight ? const Color(0xFF0B5FFF) : const Color(0xFF10B981),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    summary,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    final remarks = (eyeData['remarks'] as String?) ?? '';
    if (remarks.trim().isNotEmpty) {
      findings.add(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: isRight 
                ? const Color(0xFF0B5FFF).withOpacity(0.03)
                : const Color(0xFF10B981).withOpacity(0.03),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isRight
                  ? const Color(0xFF0B5FFF).withOpacity(0.1)
                  : const Color(0xFF10B981).withOpacity(0.1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  'Remarks',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isRight ? const Color(0xFF0B5FFF) : const Color(0xFF10B981),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  remarks,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isRight
                  ? [const Color(0xFF0B5FFF), const Color(0xFF0EA5E9)]
                  : [const Color(0xFF10B981), const Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: (isRight ? const Color(0xFF0B5FFF) : const Color(0xFF10B981)).withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isRight ? Icons.remove_red_eye : Icons.remove_red_eye_outlined,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                eyeLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (findings.isEmpty)
          const Text(
            'No findings recorded',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
              fontStyle: FontStyle.italic,
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < findings.length; i++) ...[
                findings[i],
                if (i < findings.length - 1) const SizedBox(height: 6),
              ],
            ],
          ),
      ],
    );
  }

  Map<String, dynamic> _coerceSection(dynamic raw) {
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      return {
        'selected': (m['selected'] as List?)?.cast<String>() ?? <String>[],
        'descriptions':
            Map<String, dynamic>.from(m['descriptions'] as Map? ?? {}),
        'other': (m['other'] as String?) ?? '',
      };
    }
    return {
      'selected': <String>[],
      'descriptions': <String, String>{},
      'other': '',
    };
  }

  String _formatSectionData(Map<String, dynamic> sectionData) {
    final selected =
        (sectionData['selected'] as List?)?.cast<String>() ?? <String>[];
    if (selected.isEmpty) return '';
    final descriptions =
        Map<String, dynamic>.from(sectionData['descriptions'] as Map? ?? {});
    final other = (sectionData['other'] as String?) ?? '';
    final parts = <String>[];
    for (final option in selected) {
      if (option == 'Other') {
        if (other.trim().isNotEmpty) {
          parts.add('Other: $other');
        } else {
          parts.add('Other');
        }
      } else {
        final desc = descriptions[option] as String?;
        if (desc != null && desc.trim().isNotEmpty) {
          parts.add('$option: $desc');
        } else {
          parts.add(option);
        }
      }
    }
    return parts.join(', ');
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
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

class _FollowupsTab extends ConsumerWidget {
  const _FollowupsTab({required this.caseId});
  final String caseId;

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
            actionLabel: 'Add Follow-up',
            onAction: () => context.push('/cases/$caseId/followup'),
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
                  final date =
                      f.dateOfExamination.toIso8601String().split('T').first;
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
  const _MediaTab({required this.caseId});
  final String caseId;

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
        return Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  return _MediaTile(item: item);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/cases/$caseId/media'),
                  icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
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
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
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
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(actionLabel),
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
    final profileState = ref.watch(profileControllerProvider);
    final centre = profileState.profile?.aravindCentre ??
        profileState.profile?.centre ??
        '';
    final monthKey = _monthKey(DateTime.now());
    final rosterAsync = centre.isEmpty
        ? null
        : ref.watch(
            assessmentRosterProvider((centre: centre, monthKey: monthKey)),
          );
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Submit for Assessment',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (centre.isEmpty)
                            const Text('Complete your profile centre first.')
                          else if (rosterAsync == null)
                            const SizedBox.shrink()
                          else
                            rosterAsync.when(
                              data: (list) {
                                if (list.isEmpty) {
                                  return const Text(
                                    'No consultants available for this month.',
                                  );
                                }
                                return DropdownButtonFormField<String>(
                                  value: _selectedConsultant,
                                  items: list
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c.id,
                                          child: Text(
                                            '${c.name} - ${c.designation}',
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedConsultant = v),
                                  decoration: const InputDecoration(
                                    labelText: 'Select Consultant',
                                  ),
                                );
                              },
                              loading: () =>
                                  const CircularProgressIndicator(strokeWidth: 2),
                              error: (e, _) => Text('Error: $e'),
                            ),
                        ],
                      ),
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
                label: const Text('Submit for Assessment'),
              ),
            ),
          ],
        ),
      );
    }

    final authState = ref.watch(authControllerProvider);
    final isAssignee =
        authState.session?.user.id == assessment.assignedConsultantId;
    final consultantProfileAsync =
        ref.watch(profileByIdProvider(assessment.assignedConsultantId));

    return Container(
      color: const Color(0xFFF7F9FC),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
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
                            _StatusPill(status: assessment.status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        consultantProfileAsync.when(
                          data: (profile) {
                            if (profile == null) return const SizedBox.shrink();
                            return Text(
                              'Consultant: ${profile.name} - ${profile.designation} (${profile.aravindCentre ?? profile.centre})',
                              style: const TextStyle(fontSize: 13),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        if (assessment.consultantComments != null &&
                            assessment.consultantComments.toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              assessment.consultantComments,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (widget.isConsultant &&
                    isAssignee &&
                    assessment.status != 'completed') ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add Comments',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _comments,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Enter your assessment comments...',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.isConsultant &&
              isAssignee &&
              assessment.status != 'completed') ...[
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
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _monthKey(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    return '${date.year}-$m';
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
