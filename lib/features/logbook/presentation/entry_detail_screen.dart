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
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Entry Detail',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
                              Icons.description,
                              color: Color(0xFF0B5FFF),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.patientUniqueId,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'MRN: ${entry.mrn}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _StatusBadge(status: entry.status),
                          const Spacer(),
                          Text(
                            'Updated ${_formatDate(entry.updatedAt)}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.category_outlined,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              entry.moduleType,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (entry.keywords.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: entry.keywords
                              .map(
                                (k) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
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
                  ),
                ),
                const SizedBox(height: 12),
                _AuthorInfo(author: entry.authorProfile),
                const SizedBox(height: 12),
                _PayloadView(entry: entry),
                const SizedBox(height: 12),
                _QualitySection(entry: entry),
                const SizedBox(height: 12),
                _ReviewPanel(entry: entry),
                const SizedBox(height: 12),
                _SimilarEntries(entry: entry),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                if (entry.status == statusApproved)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
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
                      icon: const Icon(Icons.school, color: Colors.white),
                      label: const Text(
                        'Propose to Teaching Library',
                        style: TextStyle(
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
                      ),
                    ),
                  ),
                if (canEdit)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => context.pushNamed(
                                'logbookEdit',
                                pathParameters: {'id': entry.id},
                                extra: entry.moduleType,
                              ),
                              icon: const Icon(Icons.edit, color: Colors.white),
                              label: const Text(
                                'Edit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0B5FFF),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
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
                              icon: const Icon(Icons.send, color: Colors.white),
                              label: Text(
                                entry.status == statusNeedsRevision
                                    ? 'Resubmit'
                                    : 'Submit',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
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
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
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
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(
                          'Delete Draft',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (!canEdit && isOwner)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Editing locked while submitted/approved/rejected. You can edit after consultant requests changes.',
                            style: TextStyle(
                              color: Color(0xFF92400E),
                              fontSize: 12,
                            ),
                          ),
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
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load entry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return date.toLocal().toString().split(' ')[0];
    }
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
                  color: const Color(0xFF0B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF0B5FFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Author',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoItem('Name', author?['name'] ?? ''),
          const SizedBox(height: 8),
          _InfoItem('Designation', author?['designation'] ?? ''),
          const SizedBox(height: 8),
          _InfoItem('Centre', author?['centre'] ?? ''),
          const SizedBox(height: 8),
          _InfoItem('Employee ID', author?['employee_id'] ?? ''),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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
          const Row(
            children: [
              Icon(
                Icons.article_outlined,
                color: Color(0xFF0B5FFF),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._buildFields(entry),
          if (videoLink != null && videoLink.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse(videoLink)),
              icon: const Icon(Icons.play_circle_outline, color: Color(0xFF0B5FFF)),
              label: const Text(
                'Open Video Link',
                style: TextStyle(
                  color: Color(0xFF0B5FFF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                side: const BorderSide(color: Color(0xFF0B5FFF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
          if (imagePaths.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Images',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
                fontSize: 14,
              ),
            ),
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
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0B5FFF),
                          ),
                        ),
                      );
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
      ),
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
      body = Row(
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 20,
            color: Colors.orange[400],
          ),
          const SizedBox(width: 8),
          const Text(
            'Awaiting consultant review',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
        ],
      );
    } else if (entry.reviewedAt != null) {
      final reviewerName = entry.reviewerProfile != null
          ? entry.reviewerProfile!['name']
          : entry.reviewedBy;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoItem('Reviewer', reviewerName ?? ''),
          const SizedBox(height: 8),
          _InfoItem('Decision', entry.status),
          if (entry.reviewComment != null && entry.reviewComment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 16,
                        color: Color(0xFF0B5FFF),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Comment',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.reviewComment!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (entry.requiredChanges.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Required changes:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            ...entry.requiredChanges.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.checklist_rtl,
                      size: 16,
                      color: Color(0xFF0B5FFF),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (entry.reviewedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Reviewed ${_formatDate(entry.reviewedAt!)}',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
              ),
            ),
          ],
        ],
      );
    } else {
      body = const Text(
        'No review yet',
        style: TextStyle(
          color: Color(0xFF64748B),
          fontSize: 14,
        ),
      );
    }

    return Container(
      width: double.infinity,
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
                Icons.rate_review_outlined,
                color: Color(0xFF0B5FFF),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Review',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return date.toLocal().toString().split(' ')[0];
    }
  }
}

class _QualitySection extends ConsumerWidget {
  const _QualitySection({required this.entry});
  final ElogEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
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
              const Icon(
                Icons.verified_outlined,
                color: Color(0xFF0B5FFF),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Quality',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Score: ${entry.qualityScore ?? 0}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B5FFF),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(qualityRepositoryProvider).scoreEntry(entry.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Re-scored entry')),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  side: const BorderSide(color: Color(0xFF0B5FFF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Re-score',
                  style: TextStyle(
                    color: Color(0xFF0B5FFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (entry.qualityIssues.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFF59E0B),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Color(0xFFD97706),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Issues Detected',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...entry.qualityIssues.map(
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              i,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Color(0xFF059669),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'No issues detected',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF065F46),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
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
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF0B5FFF),
            ),
          );
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return const SizedBox.shrink();
        }
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
              const Row(
                children: [
                  Icon(
                    Icons.compare_arrows,
                    color: Color(0xFF0B5FFF),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Similar Entries',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...list.map(
                (e) => InkWell(
                  onTap: () => context.pushNamed(
                    'logbookDetail',
                    pathParameters: {'id': e.id},
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.patientUniqueId,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        if (e.keywords.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: e.keywords.take(3).map(
                              (k) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  k,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 14,
              height: 1.5,
            ),
          ),
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
        return const Color(0xFF10B981);
      case statusSubmitted:
        return const Color(0xFF0B5FFF);
      case statusNeedsRevision:
        return const Color(0xFFF59E0B);
      case statusRejected:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _icon() {
    switch (status) {
      case statusApproved:
        return Icons.check_circle;
      case statusSubmitted:
        return Icons.send;
      case statusNeedsRevision:
        return Icons.edit_note;
      case statusRejected:
        return Icons.cancel;
      default:
        return Icons.article_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _color().withOpacity(0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon(),
            size: 16,
            color: _color(),
          ),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _color(),
            ),
          ),
        ],
      ),
    );
  }
}
