import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/application/auth_controller.dart';
import '../application/logbook_providers.dart';
import '../domain/elog_entry.dart';
import '../../quality/data/quality_repository.dart';
import '../../teaching/application/teaching_controller.dart';
import '../../quality/data/quality_repository.dart';

class EntryDetailScreen extends ConsumerWidget {
  const EntryDetailScreen({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(entryDetailProvider(entryId));
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Entry Detail')),
      body: entryAsync.when(
        data: (entry) {
          final isOwner = auth.session?.user.id == entry.createdBy;
          final canEdit = isOwner &&
              (entry.status == statusDraft || entry.status == statusNeedsRevision);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.patientUniqueId} • MRN ${entry.mrn}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatusBadge(status: entry.status),
                    const SizedBox(width: 8),
                    Text(
                      'Updated ${entry.updatedAt.toLocal()}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Module: ${entry.moduleType}'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.keywords
                      .map(
                        (k) => Chip(
                          label: Text(k),
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                _AuthorInfo(author: entry.authorProfile),
                const SizedBox(height: 16),
                _PayloadView(entry: entry),
                const SizedBox(height: 24),
                _QualitySection(entry: entry),
                const SizedBox(height: 16),
                _SimilarEntries(entry: entry),
                const SizedBox(height: 16),
                _ReviewPanel(entry: entry),
                const SizedBox(height: 16),
                if (entry.status == statusApproved)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final note = await showDialog<String>(
                        context: context,
                        builder: (_) {
                          final controller = TextEditingController();
                          return AlertDialog(
                            title: const Text('Propose to Teaching Library'),
                            content: TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                hintText: 'Optional note',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context, rootNavigator: true)
                                        .pop(null),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context, rootNavigator: true)
                                        .pop(controller.text.trim()),
                                child: const Text('Submit'),
                              ),
                            ],
                          );
                        },
                      );
                      if (note != null) {
                        try {
                          await ref
                              .read(teachingMutationProvider.notifier)
                              .propose(entry.id, note);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Proposal submitted')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('Failed: $e')));
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.school, color: Colors.black),
                    label: const Text(
                      'Propose to Teaching Library',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                if (canEdit)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => context.pushNamed(
                              'logbookEdit',
                              pathParameters: {'id': entry.id},
                              extra: entry.moduleType,
                            ),
                            icon: const Icon(Icons.edit, color: Colors.black),
                            label: const Text(
                              'Edit',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              await ref
                                  .read(entryMutationProvider.notifier)
                                  .update(
                                    entry.id,
                                    ElogEntryUpdate(
                                      status: statusSubmitted,
                                      submittedAt: DateTime.now(),
                                      clearReview: true,
                                    ),
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      entry.status == statusNeedsRevision
                                          ? 'Resubmitted for review'
                                          : 'Submitted for review',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              entry.status == statusNeedsRevision
                                  ? 'Resubmit'
                                  : 'Submit for review',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: entry.status == statusDraft
                            ? () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete entry?'),
                                    content: const Text(
                                      'This will remove the entry permanently.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context, rootNavigator: true)
                                                .pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context, rootNavigator: true)
                                                .pop(true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  await ref
                                      .read(entryMutationProvider.notifier)
                                      .delete(entry.id);
                                  if (context.mounted) {
                                    context.go('/logbook');
                                  }
                                }
                              }
                            : null,
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        label: const Text(
                          'Delete draft',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                if (!canEdit && isOwner)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Editing locked while submitted/approved/rejected. You can edit after consultant requests changes.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
      ),
    );
  }
}

class _AuthorInfo extends StatelessWidget {
  const _AuthorInfo({this.author});

  final Map<String, dynamic>? author;

  @override
  Widget build(BuildContext context) {
    if (author == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Author: ${author?['name'] ?? ''}'),
          Text('Designation: ${author?['designation'] ?? ''}'),
          Text('Centre: ${author?['centre'] ?? ''}'),
          Text('Employee ID: ${author?['employee_id'] ?? ''}'),
        ],
      ),
    );
  }
}

class _PayloadView extends ConsumerWidget {
  const _PayloadView({required this.entry});

  final ElogEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payload = entry.payload;
    final signedCache = ref.read(signedUrlCacheProvider.notifier);

    List<String> imagePaths = [];
    if (entry.moduleType == moduleCases) {
      imagePaths = [
        ...List<String>.from(payload['ancillaryImagingPaths'] ?? []),
        ...List<String>.from(payload['followUpVisitImagingPaths'] ?? []),
      ];
    } else if (entry.moduleType == moduleImages) {
      imagePaths = [
        ...List<String>.from(payload['uploadImagePaths'] ?? []),
        ...List<String>.from(payload['followUpVisitImagingPaths'] ?? []),
      ];
    }

    final videoLink = payload['surgicalVideoLink'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._buildFields(entry),
        if (videoLink != null && videoLink.isNotEmpty) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => launchUrl(Uri.parse(videoLink)),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open video link'),
          ),
        ],
        if (imagePaths.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Images', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: imagePaths.length,
            itemBuilder: (context, index) {
              final path = imagePaths[index];
              return FutureBuilder(
                future: signedCache.getUrl(path),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: InteractiveViewer(
                          child: Image.network(snapshot.data!),
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(snapshot.data!, fit: BoxFit.cover),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }

  List<Widget> _buildFields(ElogEntry entry) {
    final payload = entry.payload;
    switch (entry.moduleType) {
      case moduleCases:
        return [
          _FieldRow('Brief description', payload['briefDescription'] ?? ''),
          if ((payload['followUpVisitDescription'] ?? '').toString().isNotEmpty)
            _FieldRow('Follow up', payload['followUpVisitDescription']),
        ];
      case moduleImages:
        return [
          _FieldRow(
            'Key description / pathology',
            payload['keyDescriptionOrPathology'] ?? '',
          ),
          if ((payload['additionalInformation'] ?? '').toString().isNotEmpty)
            _FieldRow('Additional info', payload['additionalInformation']),
        ];
      case moduleLearning:
        return [
          _FieldRow(
            'Pre-op diagnosis / pathology',
            payload['preOpDiagnosisOrPathology'] ?? '',
          ),
          _FieldRow('Surgical video link', payload['surgicalVideoLink'] ?? ''),
          _FieldRow('Teaching point', payload['teachingPoint'] ?? ''),
          _FieldRow('Surgeon', payload['surgeon'] ?? ''),
        ];
      case moduleRecords:
        return [
          _FieldRow(
            'Pre-op diagnosis / pathology',
            payload['preOpDiagnosisOrPathology'] ?? '',
          ),
          _FieldRow('Surgical video link', payload['surgicalVideoLink'] ?? ''),
          _FieldRow(
            'Learning point / complication',
            payload['learningPointOrComplication'] ?? '',
          ),
          _FieldRow(
            'Surgeon or assistant',
            payload['surgeonOrAssistant'] ?? '',
          ),
        ];
      default:
        return [];
    }
  }
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({required this.entry});

  final ElogEntry entry;

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (entry.status == statusSubmitted && entry.reviewedAt == null) {
      body = const Text('Awaiting consultant review');
    } else if (entry.reviewedAt != null) {
      final reviewerName = entry.reviewerProfile != null
          ? entry.reviewerProfile!['name']
          : entry.reviewedBy;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reviewer: ${reviewerName ?? ''}'),
          Text('Decision: ${entry.status}'),
          if (entry.reviewComment != null && entry.reviewComment!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Comment: ${entry.reviewComment}'),
            ),
          if (entry.requiredChanges.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Required changes:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            ...entry.requiredChanges.map(
              (c) => Row(
                children: [
                  const Icon(Icons.checklist_rtl, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text(c.toString())),
                ],
              ),
            ),
          ],
          if (entry.reviewedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Reviewed at: ${entry.reviewedAt!.toLocal()}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
        ],
      );
    } else {
      body = const Text('No review yet');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          body,
        ],
      ),
    );
  }
}

class _QualitySection extends ConsumerWidget {
  const _QualitySection({required this.entry});
  final ElogEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Quality',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text('Score: ${entry.qualityScore ?? 0}'),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () async {
                  await ref.read(qualityRepositoryProvider).scoreEntry(entry.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Re-scored entry')),
                    );
                  }
                },
                child: const Text('Re-score'),
              ),
            ],
          ),
          if (entry.qualityIssues.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Issues:', style: TextStyle(color: Colors.orangeAccent)),
            ...entry.qualityIssues.map((i) => Text('- $i')),
          ] else
            const Text('No issues detected'),
        ],
      ),
    );
  }
}

class _SimilarEntries extends ConsumerWidget {
  const _SimilarEntries({required this.entry});
  final ElogEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(qualityRepositoryProvider);
    return FutureBuilder(
      future: repo.similarEntries(entry),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Similar entries',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...list.map(
              (e) => ListTile(
                title: Text(e.patientUniqueId),
                subtitle: Text(e.keywords.take(3).join(', ')),
                onTap: () => context.pushNamed(
                  'logbookDetail',
                  pathParameters: {'id': e.id},
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  Color _color() {
    switch (status) {
      case statusApproved:
        return Colors.green.withValues(alpha: 0.2);
      case statusSubmitted:
        return Colors.blue.withValues(alpha: 0.2);
      case statusNeedsRevision:
        return Colors.orange.withValues(alpha: 0.2);
      case statusRejected:
        return Colors.red.withValues(alpha: 0.2);
      default:
        return Colors.white.withValues(alpha: 0.1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _color(),
      ),
      child: Text(
        status,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
