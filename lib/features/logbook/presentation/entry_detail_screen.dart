import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/application/auth_controller.dart';
import '../../profile/application/profile_controller.dart';
import '../application/logbook_providers.dart';
import '../domain/elog_entry.dart';

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
          final canEdit =
              isOwner &&
              (ref.read(profileControllerProvider).profile?.designation !=
                  'Consultant');
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
                if (canEdit)
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
                      TextButton.icon(
                        onPressed: () async {
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
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
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
                        },
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        label: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
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
        if (videoLink != null) ...[
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
