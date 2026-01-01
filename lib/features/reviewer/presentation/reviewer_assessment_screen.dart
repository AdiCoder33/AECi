import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../clinical_cases/data/clinical_cases_repository.dart';
import '../../logbook/data/entries_repository.dart';
import '../application/reviewer_controller.dart';
import '../data/reviewer_repository.dart';
import '../domain/oscar_rubric.dart';
import 'widgets/reviewer_app_bar_actions.dart';

class ReviewerAssessmentScreen extends ConsumerStatefulWidget {
  const ReviewerAssessmentScreen({super.key, required this.item});

  final ReviewItem item;

  @override
  ConsumerState<ReviewerAssessmentScreen> createState() =>
      _ReviewerAssessmentScreenState();
}

class _ReviewerAssessmentScreenState
    extends ConsumerState<ReviewerAssessmentScreen> {
  final _remarksController = TextEditingController();
  int _caseScore = 5;
  final Map<String, int> _oscarScores = {};

  @override
  void initState() {
    super.initState();
    for (final criterion in oscarRubric) {
      _oscarScores[criterion.label] = 0;
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCase = widget.item.entityType == 'clinical_case';
    final mutation = ref.watch(reviewerMutationProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(isCase ? 'Case Review' : 'Surgical Video Review'),
        actions: const [ReviewerAppBarActions()],
      ),
      body: isCase ? _buildClinicalCase(context) : _buildVideo(context),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: mutation.isLoading ? null : _submit,
            child: mutation.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Submit Review'),
          ),
        ),
      ),
    );
  }

  Widget _buildClinicalCase(BuildContext context) {
    final repo = ref.watch(clinicalCasesRepositoryProvider);
    return FutureBuilder<ClinicalCase>(
      future: repo.getCase(widget.item.entityId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final c = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InfoCard(
              title: 'Case Summary',
              children: [
                _InfoRow(label: 'Patient', value: c.patientName),
                _InfoRow(label: 'UID', value: c.uidNumber),
                _InfoRow(label: 'MR', value: c.mrNumber),
                _InfoRow(label: 'Diagnosis', value: c.diagnosis),
              ],
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Score (0-10)',
              children: [
                DropdownButtonFormField<int>(
                  value: _caseScore,
                  items: List.generate(
                    11,
                    (i) => DropdownMenuItem(value: i, child: Text('$i')),
                  ),
                  onChanged: (value) =>
                      setState(() => _caseScore = value ?? 0),
                  decoration: const InputDecoration(labelText: 'Score'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Remarks',
              children: [
                TextField(
                  controller: _remarksController,
                  maxLines: 4,
                  decoration:
                      const InputDecoration(hintText: 'Enter remarks'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildVideo(BuildContext context) {
    final entriesRepo = ref.watch(entriesRepositoryProvider);
    return FutureBuilder(
      future: entriesRepo.getEntry(widget.item.entityId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final entry = snapshot.data!;
        final payload = entry.payload;
        final link = (payload['surgicalVideoLink'] as String?) ?? '';
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InfoCard(
              title: 'Video Summary',
              children: [
                _InfoRow(
                  label: 'Patient',
                  value: '${entry.patientUniqueId} / ${entry.mrn}',
                ),
                _InfoRow(label: 'Module', value: entry.moduleType),
                if (link.trim().isNotEmpty)
                  TextButton.icon(
                    onPressed: () => launchUrl(Uri.parse(link)),
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Open video'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'OSCAR (draft rubric)',
              children: [
                for (final criterion in oscarRubric) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          criterion.label,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 100,
                        child: DropdownButtonFormField<int>(
                          value: _oscarScores[criterion.label],
                          items: List.generate(
                            criterion.maxScore + 1,
                            (i) => DropdownMenuItem(
                              value: i,
                              child: Text('$i'),
                            ),
                          ),
                          onChanged: (value) => setState(() {
                            _oscarScores[criterion.label] = value ?? 0;
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Remarks',
              children: [
                TextField(
                  controller: _remarksController,
                  maxLines: 4,
                  decoration:
                      const InputDecoration(hintText: 'Enter remarks'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total score: ${_oscarTotal()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        );
      },
    );
  }

  int _oscarTotal() {
    return _oscarScores.values.fold(0, (sum, v) => sum + v);
  }

  Future<void> _submit() async {
    final mutation = ref.read(reviewerMutationProvider.notifier);
    if (widget.item.entityType == 'clinical_case') {
      await mutation.submitClinicalCase(
        caseId: widget.item.entityId,
        traineeId: widget.item.traineeId,
        score: _caseScore,
        remarks: _remarksController.text.trim(),
      );
    } else {
      final scores = oscarRubric
          .map((c) => {
                'criterion': c.label,
                'score': _oscarScores[c.label] ?? 0,
                'maxScore': c.maxScore,
              })
          .toList();
      await mutation.submitSurgicalVideo(
        entryId: widget.item.entityId,
        traineeId: widget.item.traineeId,
        oscarScores: scores,
        totalScore: _oscarTotal(),
        remarks: _remarksController.text.trim(),
      );
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
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
            width: 90,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
