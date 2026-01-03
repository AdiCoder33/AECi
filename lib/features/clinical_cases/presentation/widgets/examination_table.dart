import 'package:flutter/material.dart';

import '../../domain/constants/anterior_segment_options.dart';
import '../../domain/constants/fundus_options.dart';

class ExaminationTableRow extends StatelessWidget {
  const ExaminationTableRow({
    super.key,
    required this.label,
    required this.rightValue,
    required this.leftValue,
  });

  final String label;
  final String rightValue;
  final String leftValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFA),
                border: Border(
                  right: BorderSide(color: Color(0xFFE2E8F0), width: 0.5),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7).withOpacity(0.2),
                border: const Border(
                  right: BorderSide(color: Color(0xFFE2E8F0), width: 0.5),
                ),
              ),
              child: Text(
                rightValue,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE).withOpacity(0.2),
              ),
              child: Text(
                leftValue,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildAnteriorSegmentTable(Map<String, dynamic>? anterior) {
  if (anterior == null || anterior.isEmpty) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
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
  final topRemarks = (anterior['remarks'] as String?) ?? '';

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
    ),
    child: Column(
      children: [
        // Header row
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text(
                  'Parameter',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.visibility,
                        size: 14,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Right Eye',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.visibility,
                        size: 14,
                        color: Color(0xFF0B5FFF),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Left Eye',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Data rows
        ...anteriorSegmentSections.map((section) {
          final reSection = _coerceSection(reData[section.key]);
          final leSection = _coerceSection(leData[section.key]);
          final reSummary = _formatSection(reSection);
          final leSummary = _formatSection(leSection);
          
          if (reSummary.isEmpty && leSummary.isEmpty) {
            return const SizedBox.shrink();
          }
          
          return ExaminationTableRow(
            label: section.label,
            rightValue: reSummary.isEmpty ? '-' : reSummary,
            leftValue: leSummary.isEmpty ? '-' : leSummary,
          );
        }).toList(),
        // Remarks
        if (topRemarks.trim().isNotEmpty ||
            (reData['remarks'] as String? ?? '').trim().isNotEmpty ||
            (leData['remarks'] as String? ?? '').trim().isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7).withOpacity(0.3),
              border: const Border(
                top: BorderSide(color: Color(0xFFE2E8F0)),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.note_outlined,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Remarks',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if ((reData['remarks'] as String? ?? '').trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'RE: ${reData['remarks']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                if ((leData['remarks'] as String? ?? '').trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'LE: ${leData['remarks']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                if (topRemarks.trim().isNotEmpty)
                  Text(
                    topRemarks,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

Widget buildFundusTable(Map<String, dynamic>? fundus) {
  if (fundus == null || fundus.isEmpty) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
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

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
    ),
    child: Column(
      children: [
        // Header row
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text(
                  'Parameter',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.visibility,
                        size: 14,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Right Eye',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.visibility,
                        size: 14,
                        color: Color(0xFF0B5FFF),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Left Eye',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Data rows
        ...fundusSections.map((section) {
          final reSection = _coerceSection(reData[section.key]);
          final leSection = _coerceSection(leData[section.key]);
          final reSummary = _formatSection(reSection);
          final leSummary = _formatSection(leSection);
          
          if (reSummary.isEmpty && leSummary.isEmpty) {
            return const SizedBox.shrink();
          }
          
          return ExaminationTableRow(
            label: section.label,
            rightValue: reSummary.isEmpty ? '-' : reSummary,
            leftValue: leSummary.isEmpty ? '-' : leSummary,
          );
        }).toList(),
        // Remarks
        if ((reData['remarks'] as String? ?? '').trim().isNotEmpty ||
            (leData['remarks'] as String? ?? '').trim().isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7).withOpacity(0.3),
              border: const Border(
                top: BorderSide(color: Color(0xFFE2E8F0)),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.note_outlined,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Remarks',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if ((reData['remarks'] as String? ?? '').trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'RE: ${reData['remarks']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                if ((leData['remarks'] as String? ?? '').trim().isNotEmpty)
                  Text(
                    'LE: ${leData['remarks']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

Map<String, dynamic> _coerceSection(dynamic section) {
  if (section is Map<String, dynamic>) {
    return section;
  } else if (section is Map) {
    return Map<String, dynamic>.from(section);
  }
  return {};
}

String _formatSection(Map<String, dynamic> section) {
  final items = <String>[];
  for (final entry in section.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key == 'remarks') continue;
    if (value == null || value.toString().trim().isEmpty) continue;
    if (value is bool && !value) continue;
    if (value is List && value.isEmpty) continue;
    if (value is List) {
      items.add('${_label(key)}: ${value.join(", ")}');
    } else if (value is bool) {
      items.add(_label(key));
    } else {
      items.add('${_label(key)}: $value');
    }
  }
  return items.join(', ');
}

String _label(String key) {
  return key.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}
