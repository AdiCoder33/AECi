import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../logbook/application/logbook_providers.dart';
import 'application/teaching_controller.dart'
    show proposalListProvider, teachingMutationProvider;
import 'data/teaching_repository.dart';

class TeachingProposalsScreen extends ConsumerWidget {
  const TeachingProposalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposals = ref.watch(proposalListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Teaching Proposals')),
      body: proposals.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No proposals'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final p = list[i];
              return ListTile(
                title: Text(p.entryId),
                subtitle: Text('Status: ${p.status}'),
                onTap: () => context.pushNamed(
                  'proposalReview',
                  pathParameters: {'id': p.entryId, 'proposalId': p.id},
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class ProposalReviewScreen extends ConsumerStatefulWidget {
  const ProposalReviewScreen({super.key, required this.entryId, required this.proposalId});
  final String entryId;
  final String proposalId;

  @override
  ConsumerState<ProposalReviewScreen> createState() => _ProposalReviewScreenState();
}

class _ProposalReviewScreenState extends ConsumerState<ProposalReviewScreen> {
  final _title = TextEditingController();
  final _summary = TextEditingController();
  String _scope = 'centre';

  @override
  Widget build(BuildContext context) {
    final entryAsync = ref.watch(entryDetailProvider(widget.entryId));
    final mutation = ref.watch(teachingMutationProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Review Proposal')),
      body: entryAsync.when(
        data: (entry) => Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text('Entry: ${entry.patientUniqueId}'),
              const SizedBox(height: 8),
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Teaching title'),
              ),
              TextField(
                controller: _summary,
                decoration: const InputDecoration(labelText: 'Summary'),
                maxLines: 3,
              ),
              DropdownButtonFormField<String>(
                value: _scope,
                items: const [
                  DropdownMenuItem(value: 'private', child: Text('Private')),
                  DropdownMenuItem(value: 'centre', child: Text('Centre')),
                  DropdownMenuItem(value: 'institution', child: Text('Institution')),
                ],
                onChanged: (v) => setState(() => _scope = v ?? 'centre'),
                decoration: const InputDecoration(labelText: 'Share scope'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: mutation.isLoading
                        ? null
                        : () async {
                            await ref
                                .read(teachingMutationProvider.notifier)
                                .reviewProposal(widget.proposalId, 'approved');
                            final centre = entry.authorProfile?['centre'] ?? 'Chennai';
                            await ref.read(teachingMutationProvider.notifier).publish(
                                  entry: entry,
                                  title: _title.text.isEmpty ? entry.patientUniqueId : _title.text,
                                  summary: _summary.text,
                                  shareScope: _scope,
                                  centre: centre,
                                );
                            if (mounted) {
                              context.pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Published to teaching')),
                              );
                            }
                          },
                    child: const Text('Publish'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(teachingMutationProvider.notifier)
                          .reviewProposal(widget.proposalId, 'rejected');
                      if (mounted) context.pop();
                    },
                    child: const Text('Reject'),
                  ),
                ],
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
