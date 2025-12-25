import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/clinical_cases_controller.dart';
import '../data/clinical_case_constants.dart';
import '../data/clinical_cases_repository.dart';

class CaseFollowupFormScreen extends ConsumerStatefulWidget {
  const CaseFollowupFormScreen({
    super.key,
    required this.caseId,
    this.followupId,
  });

  final String caseId;
  final String? followupId;

  @override
  ConsumerState<CaseFollowupFormScreen> createState() =>
      _CaseFollowupFormScreenState();
}

class _CaseFollowupFormScreenState
    extends ConsumerState<CaseFollowupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ucvaRe = TextEditingController();
  final _ucvaLe = TextEditingController();
  final _iopRe = TextEditingController();
  final _iopLe = TextEditingController();
  final _anterior = TextEditingController();
  final _fundus = TextEditingController();
  final _management = TextEditingController();
  DateTime _examDate = DateTime.now();
  int _intervalDays = 0;
  String _bcvaRe = '';
  String _bcvaLe = '';
  bool _copyAnterior = false;
  bool _copyFundus = false;
  bool _initialized = false;

  @override
  void dispose() {
    _ucvaRe.dispose();
    _ucvaLe.dispose();
    _iopRe.dispose();
    _iopLe.dispose();
    _anterior.dispose();
    _fundus.dispose();
    _management.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caseAsync = ref.watch(clinicalCaseDetailProvider(widget.caseId));
    final followupsAsync = ref.watch(caseFollowupsProvider(widget.caseId));
    final repo = ref.watch(clinicalCasesRepositoryProvider);

    return caseAsync.when(
      data: (caseData) {
        return FutureBuilder<CaseFollowup?>(
          future: widget.followupId == null
              ? Future.value(null)
              : repo.getFollowup(widget.followupId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final existing = snapshot.data;
            if (!_initialized) {
              _initialized = true;
              if (existing != null) {
                _examDate = existing.dateOfExamination;
                _intervalDays = existing.intervalDays;
                _ucvaRe.text = existing.ucvaRe ?? '';
                _ucvaLe.text = existing.ucvaLe ?? '';
                _bcvaRe = existing.bcvaRe ?? '';
                _bcvaLe = existing.bcvaLe ?? '';
                _iopRe.text = existing.iopRe?.toString() ?? '';
                _iopLe.text = existing.iopLe?.toString() ?? '';
                _anterior.text = existing.anteriorSegmentFindings ?? '';
                _fundus.text = existing.fundusFindings ?? '';
                _management.text = existing.management ?? '';
              }
            }

            final followups = followupsAsync.value ?? [];
            final lastFollowup =
                followups.isNotEmpty ? followups.last : null;
            final previousDate = lastFollowup?.dateOfExamination ??
                caseData.dateOfExamination;
            final prevAnterior = lastFollowup?.anteriorSegmentFindings ??
                _formatAnterior(caseData.anteriorSegment);
            final prevFundus =
                lastFollowup?.fundusFindings ?? _formatFundus(caseData.fundus);

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  widget.followupId == null
                      ? 'Add Follow-up'
                      : 'Edit Follow-up',
                ),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date of Examination',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _examDate,
                            firstDate: DateTime(now.year - 5),
                            lastDate: now,
                          );
                          if (picked != null) {
                            setState(() {
                              _examDate = picked;
                              _intervalDays =
                                  _examDate.difference(previousDate).inDays;
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _formatDate(_examDate),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ReadonlyTile(
                        label: 'Follow-up interval',
                        value: _intervalDays <= 0
                            ? 'Same day'
                            : _friendlyInterval(_intervalDays),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ucvaRe,
                        decoration:
                            const InputDecoration(labelText: 'UCVA - RE'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ucvaLe,
                        decoration:
                            const InputDecoration(labelText: 'UCVA - LE'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _bcvaRe.isEmpty ? null : _bcvaRe,
                        items: bcvaOptions
                            .map((o) =>
                                DropdownMenuItem(value: o, child: Text(o)))
                            .toList(),
                        decoration:
                            const InputDecoration(labelText: 'BCVA - RE'),
                        onChanged: (v) =>
                            setState(() => _bcvaRe = v ?? ''),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _bcvaLe.isEmpty ? null : _bcvaLe,
                        items: bcvaOptions
                            .map((o) =>
                                DropdownMenuItem(value: o, child: Text(o)))
                            .toList(),
                        decoration:
                            const InputDecoration(labelText: 'BCVA - LE'),
                        onChanged: (v) =>
                            setState(() => _bcvaLe = v ?? ''),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _iopRe,
                        decoration:
                            const InputDecoration(labelText: 'IOP - RE'),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: _numberValidator,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _iopLe,
                        decoration:
                            const InputDecoration(labelText: 'IOP - LE'),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: _numberValidator,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Copy previous Anterior findings'),
                        value: _copyAnterior,
                        onChanged: (value) {
                          setState(() {
                            _copyAnterior = value;
                            if (value) {
                              _anterior.text = prevAnterior;
                            }
                          });
                        },
                      ),
                      TextFormField(
                        controller: _anterior,
                        decoration: const InputDecoration(
                          labelText: 'Anterior segment findings',
                        ),
                        maxLines: 3,
                        enabled: !_copyAnterior,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Copy previous Fundus findings'),
                        value: _copyFundus,
                        onChanged: (value) {
                          setState(() {
                            _copyFundus = value;
                            if (value) {
                              _fundus.text = prevFundus;
                            }
                          });
                        },
                      ),
                      TextFormField(
                        controller: _fundus,
                        decoration: const InputDecoration(
                          labelText: 'Fundus findings',
                        ),
                        maxLines: 3,
                        enabled: !_copyFundus,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _management,
                        decoration:
                            const InputDecoration(labelText: 'Management'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _saveFollowup(
                            caseData,
                            previousDate,
                            existing,
                          ),
                          child: Text(widget.followupId == null
                              ? 'Save Follow-up'
                              : 'Update Follow-up'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Future<void> _saveFollowup(
    ClinicalCase caseData,
    DateTime previousDate,
    CaseFollowup? existing,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    if (existing == null && _examDate.isBefore(previousDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Follow-up date must be after previous visit.')),
      );
      return;
    }
    final followups = ref.read(caseFollowupsProvider(widget.caseId)).value ?? [];
    final nextIndex = existing?.followupIndex ?? (followups.length + 1);
    final data = {
      'followup_index': nextIndex,
      'date_of_examination': _examDate.toIso8601String().split('T').first,
      'interval_days': _intervalDays,
      'ucva_re': _ucvaRe.text.trim(),
      'ucva_le': _ucvaLe.text.trim(),
      'bcva_re': _bcvaRe,
      'bcva_le': _bcvaLe,
      'iop_re': num.tryParse(_iopRe.text),
      'iop_le': num.tryParse(_iopLe.text),
      'anterior_segment_findings': _anterior.text.trim(),
      'fundus_findings': _fundus.text.trim(),
      'management': _management.text.trim(),
    };
    try {
      if (existing == null) {
        await ref
            .read(clinicalCaseMutationProvider.notifier)
            .addFollowup(widget.caseId, data);
      } else {
        await ref
            .read(clinicalCaseMutationProvider.notifier)
            .updateFollowup(existing.id, data);
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save follow-up: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _friendlyInterval(int days) {
    if (days % 30 == 0) {
      final months = days ~/ 30;
      return '$months month${months == 1 ? '' : 's'}';
    }
    if (days % 7 == 0) {
      final weeks = days ~/ 7;
      return '$weeks week${weeks == 1 ? '' : 's'}';
    }
    return '$days days';
  }

  String _formatAnterior(Map<String, dynamic>? anterior) {
    if (anterior == null || anterior.isEmpty) return '-';
    final lines = <String>[];
    for (final eyeKey in ['RE', 'LE']) {
      final eye = Map<String, dynamic>.from(anterior[eyeKey] as Map? ?? {});
      final abnormal = <String>[];
      for (final field in anteriorSegments) {
        final data = Map<String, dynamic>.from(eye[field] as Map? ?? {});
        final status = (data['status'] as String?) ?? 'normal';
        final notes = (data['notes'] as String?) ?? '';
        if (status == 'abnormal') {
          abnormal.add('$field: $notes');
        }
      }
      lines.add(abnormal.isEmpty ? '$eyeKey: All normal' : '$eyeKey: ${abnormal.join('; ')}');
    }
    return lines.join('\n');
  }

  String _formatFundus(Map<String, dynamic>? fundus) {
    if (fundus == null || fundus.isEmpty) return '-';
    final lines = <String>[];
    for (final field in fundusFields) {
      final value = (fundus[field] as String?) ?? '-';
      lines.add('${field.toUpperCase()}: $value');
    }
    final others = (fundus['others'] as String?) ?? '';
    if (others.trim().isNotEmpty) {
      lines.add('OTHERS: $others');
    }
    return lines.join('\n');
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (num.tryParse(value) == null) return 'Enter a valid number';
    return null;
  }
}

class _ReadonlyTile extends StatelessWidget {
  const _ReadonlyTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
