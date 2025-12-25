import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../logbook/application/logbook_providers.dart';
import '../../logbook/domain/elog_entry.dart';
import '../application/review_controller.dart';

class ReviewDetailScreen extends ConsumerStatefulWidget {
  const ReviewDetailScreen({super.key, required this.entryId});

  final String entryId;

  @override
  ConsumerState<ReviewDetailScreen> createState() =>
      _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends ConsumerState<ReviewDetailScreen> {
  String _decision = 'needs_revision';
  final _commentController = TextEditingController();
  final _requiredChangesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final entryAsync = ref.watch(entryDetailProvider(widget.entryId));

    return Scaffold(
      appBar: AppBar(title: const Text('Review Entry')),
      body: entryAsync.when(
        data: (entry) => Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text('${entry.patientUniqueId} • MRN ${entry.mrn}',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Module: ${entry.moduleType}'),
              const SizedBox(height: 12),
              Text('Summary: ${_primaryField(entry)}'),
              const SizedBox(height: 12),
              Text('Status: ${entry.status}'),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _decision,
                items: const [
                  DropdownMenuItem(
                    value: 'approved',
                    child: Text('Approve'),
                  ),
                  DropdownMenuItem(
                    value: 'needs_revision',
                    child: Text('Return for Revision'),
                  ),
                  DropdownMenuItem(
                    value: 'rejected',
                    child: Text('Reject'),
                  ),
                ],
                onChanged: (v) => setState(() => _decision = v ?? 'needs_revision'),
                decoration: const InputDecoration(labelText: 'Decision'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Comment',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _requiredChangesController,
                decoration: const InputDecoration(
                  labelText: 'Required changes (comma separated)',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _submitReview(context),
                child: const Text('Submit Review'),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _primaryField(ElogEntry entry) {
    final p = entry.payload;
    switch (entry.moduleType) {
      case moduleCases:
        return (p['briefDescription'] ?? '').toString();
      case moduleImages:
        return (p['keyDescriptionOrPathology'] ?? '').toString();
      case moduleLearning:
        return (p['teachingPoint'] ?? '').toString();
      case moduleRecords:
        return (p['learningPointOrComplication'] ??
                p['preOpDiagnosisOrPathology'] ??
                '')
            .toString();
      default:
        return '';
    }
  }

  Future<void> _submitReview(BuildContext context) async {
    final requiredChanges = _requiredChangesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    await ref.read(reviewControllerProvider.notifier).review(
          entryId: widget.entryId,
          decision: _decision,
          comment: _commentController.text.trim(),
          requiredChanges: requiredChanges,
        );
    await ref.read(reviewControllerProvider.notifier).loadQueue();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Review submitted')));
      context.go('/review-queue');
    }
  }
}
