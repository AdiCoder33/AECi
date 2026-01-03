import 'package:flutter/material.dart';

class WizardHeader extends StatelessWidget {
  const WizardHeader({
    super.key,
    required this.step,
    required this.total,
    required this.title,
    this.patientInfo,
  });

  final int step;
  final int total;
  final String title;
  final PatientInfoSummary? patientInfo;

  @override
  Widget build(BuildContext context) {
    final progress = step / total;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.adjust_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Step $step of $total',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF34D399)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (patientInfo != null) ...[
            const SizedBox(height: 12),
            patientInfo!,
          ],
        ],
      ),
    );
  }
}

class PatientInfoSummary extends StatefulWidget {
  const PatientInfoSummary({
    super.key,
    required this.patientName,
    required this.uidNumber,
    required this.mrNumber,
    required this.age,
    required this.gender,
    required this.examDate,
  });

  final String patientName;
  final String uidNumber;
  final String mrNumber;
  final String age;
  final String gender;
  final String examDate;

  @override
  State<PatientInfoSummary> createState() => _PatientInfoSummaryState();
}

class _PatientInfoSummaryState extends State<PatientInfoSummary> {
  bool _hideUid = false;
  bool _hideMr = false;

  String _maskString(String value) {
    if (value.isEmpty) return '-';
    if (value.length <= 2) return '**';
    return value.substring(0, 2) + ('*' * (value.length - 2));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.person_outline, color: Colors.white, size: 24),
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
          // Content
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InfoRow(
                        label: 'Patient',
                        value: widget.patientName.isEmpty
                            ? '-'
                            : widget.patientName,
                      ),
                    ),
                    Expanded(
                      child: _InfoRow(
                        label: 'Gender',
                        value: widget.gender.isEmpty ? '-' : widget.gender,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _InfoRowWithIcon(
                        label: 'UID',
                        value: _hideUid
                            ? _maskString(widget.uidNumber)
                            : (widget.uidNumber.isEmpty
                                  ? '-'
                                  : widget.uidNumber),
                        isHidden: _hideUid,
                        onToggle: () => setState(() => _hideUid = !_hideUid),
                      ),
                    ),
                    Expanded(
                      child: _InfoRow(
                        label: 'Age',
                        value: widget.age.isEmpty ? '-' : widget.age,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _InfoRowWithIcon(
                        label: 'MR Number',
                        value: _hideMr
                            ? _maskString(widget.mrNumber)
                            : (widget.mrNumber.isEmpty ? '-' : widget.mrNumber),
                        isHidden: _hideMr,
                        onToggle: () => setState(() => _hideMr = !_hideMr),
                      ),
                    ),
                    Expanded(
                      child: _InfoRow(
                        label: 'Exam Date',
                        value: widget.examDate.isEmpty ? '-' : widget.examDate,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
          value,
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

class _InfoRowWithIcon extends StatelessWidget {
  const _InfoRowWithIcon({
    required this.label,
    required this.value,
    required this.isHidden,
    required this.onToggle,
  });

  final String label;
  final String value;
  final bool isHidden;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onToggle,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  isHidden ? Icons.visibility_off : Icons.visibility,
                  size: 16,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
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
