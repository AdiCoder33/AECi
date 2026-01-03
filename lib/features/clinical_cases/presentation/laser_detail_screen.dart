import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../application/clinical_cases_controller.dart';
import '../data/clinical_cases_repository.dart';

class LaserDetailScreen extends ConsumerWidget {
  const LaserDetailScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseAsync = ref.watch(clinicalCaseDetailProvider(caseId));
    final mediaAsync = ref.watch(caseMediaProvider(caseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laser'),
        actions: [
          caseAsync.maybeWhen(
            data: (c) => IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/cases/${c.id}/edit?type=laser'),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: caseAsync.when(
        data: (c) {
          final anterior = c.anteriorSegment ?? const <String, dynamic>{};
          final laser = Map<String, dynamic>.from(anterior['laser'] as Map? ?? {});
          final bcva =
              Map<String, dynamic>.from(laser['bcva_pre'] as Map? ?? {});
          final diagnosis =
              Map<String, dynamic>.from(laser['diagnosis'] as Map? ?? {});
          final laserType =
              Map<String, dynamic>.from(laser['laser_type'] as Map? ?? {});
          final params =
              Map<String, dynamic>.from(laser['parameters'] as Map? ?? {});
          final paramsByEye = params.containsKey('RE') || params.containsKey('LE');

          final followupsAsync = ref.watch(caseFollowupsProvider(caseId));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                title: 'Patient Details',
                child: Column(
                  children: [
                    _InfoRow(label: 'Patient', value: c.patientName),
                    _InfoRow(label: 'UID', value: c.uidNumber),
                    _InfoRow(label: 'MRN', value: c.mrNumber),
                    _InfoRow(label: 'Gender', value: c.patientGender),
                    _InfoRow(label: 'Age', value: c.patientAge.toString()),
                    _InfoRow(label: 'Exam Date', value: _fmtDate(c.dateOfExamination)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Laser Details',
                child: Column(
                  children: [
                    _EyePairRow(
                      label: 'BCVA (pre-laser)',
                      right: _mapEyeValue(bcva, 'RE'),
                      left: _mapEyeValue(bcva, 'LE'),
                    ),
                    const SizedBox(height: 8),
                    _EyePairRow(
                      label: 'Diagnosis',
                      right: _mapEyeValue(diagnosis, 'RE'),
                      left: _mapEyeValue(diagnosis, 'LE'),
                    ),
                    const SizedBox(height: 8),
                    _EyePairRow(
                      label: 'Laser type',
                      right: _mapEyeValue(laserType, 'RE'),
                      left: _mapEyeValue(laserType, 'LE'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_hasParams(params))
                _SectionCard(
                  title: 'Laser Parameters',
                  child: Column(
                    children: [
                      if (paramsByEye) ...[
                        _EyePairRow(
                          label: 'Power (mW)',
                          right: _paramEye(params, 'RE', 'power_mw'),
                          left: _paramEye(params, 'LE', 'power_mw'),
                        ),
                        _EyePairRow(
                          label: 'Duration (ms)',
                          right: _paramEye(params, 'RE', 'duration_ms'),
                          left: _paramEye(params, 'LE', 'duration_ms'),
                        ),
                        _EyePairRow(
                          label: 'Interval',
                          right: _paramEye(params, 'RE', 'interval'),
                          left: _paramEye(params, 'LE', 'interval'),
                        ),
                        _EyePairRow(
                          label: 'Spot size (um)',
                          right: _paramEye(params, 'RE', 'spot_size_um'),
                          left: _paramEye(params, 'LE', 'spot_size_um'),
                        ),
                        _EyePairRow(
                          label: 'Pattern',
                          right: _paramEye(params, 'RE', 'pattern'),
                          left: _paramEye(params, 'LE', 'pattern'),
                        ),
                        _EyePairRow(
                          label: 'Spot spacing',
                          right: _paramEye(params, 'RE', 'spot_spacing'),
                          left: _paramEye(params, 'LE', 'spot_spacing'),
                        ),
                        _EyePairRow(
                          label: 'Burn intensity',
                          right: _paramEye(params, 'RE', 'burn_intensity'),
                          left: _paramEye(params, 'LE', 'burn_intensity'),
                        ),
                      ] else ...[
                        _InfoRow(label: 'Power (mW)', value: _param(params, 'power_mw')),
                        _InfoRow(label: 'Duration (ms)', value: _param(params, 'duration_ms')),
                        _InfoRow(label: 'Interval', value: _param(params, 'interval')),
                        _InfoRow(label: 'Spot size (um)', value: _param(params, 'spot_size_um')),
                        _InfoRow(label: 'Pattern', value: _param(params, 'pattern')),
                        _InfoRow(label: 'Spot spacing', value: _param(params, 'spot_spacing')),
                        _InfoRow(label: 'Burn intensity', value: _param(params, 'burn_intensity')),
                      ],
                    ],
                    ),
                ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Media',
                child: mediaAsync.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('No media uploaded yet.'),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () =>
                                context.push('/cases/$caseId/media'),
                            icon: const Icon(Icons.add_photo_alternate_outlined),
                            label: const Text('Add Media'),
                          ),
                        ],
                      );
                    }

                    final preview = list.take(4).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: preview.length,
                          itemBuilder: (context, index) =>
                              _LaserMediaTile(item: preview[index]),
                        ),
                        if (list.length > preview.length) ...[
                          const SizedBox(height: 8),
                          Text(
                            '+${list.length - preview.length} more',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () =>
                                context.push('/cases/$caseId/media'),
                            child: const Text('View all media'),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Failed to load media: $e'),
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Laser Follow-ups',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EyePairRow(
                      label: 'Pre-laser BCVA',
                      right: _mapEyeValue(bcva, 'RE'),
                      left: _mapEyeValue(bcva, 'LE'),
                    ),
                    const SizedBox(height: 12),
                    followupsAsync.when(
                      data: (list) {
                        if (list.isEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('No follow-ups yet.'),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    context.push('/cases/$caseId/followup'),
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: const Text('Add Follow-up'),
                              ),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: list.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final f = list[index];
                                final date = _fmtDate(f.dateOfExamination);
                                final interval = f.intervalDays <= 0
                                    ? 'Same day'
                                    : _friendlyInterval(f.intervalDays);
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        const SizedBox(height: 6),
                                        Text('Interval: $interval'),
                                        const SizedBox(height: 8),
                                        _EyePairRow(
                                          label: 'BCVA',
                                          right: _safeText(f.bcvaRe),
                                          left: _safeText(f.bcvaLe),
                                        ),
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
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    context.push('/cases/$caseId/followup'),
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: const Text('Add Follow-up'),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Failed to load follow-ups: $e'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _LaserMediaTile extends ConsumerWidget {
  const _LaserMediaTile({required this.item});

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
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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

String _fmtDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _safeText(String? value) {
  if (value == null) return '-';
  final text = value.trim();
  return text.isEmpty ? '-' : text;
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

String _mapEyeValue(Map<String, dynamic> map, String eye) {
  final value = map[eye];
  if (value == null || value.toString().trim().isEmpty) return '-';
  return value.toString();
}

bool _hasParams(Map<String, dynamic> params) {
  if (params.isEmpty) return false;
  if (params.containsKey('RE') || params.containsKey('LE')) {
    final re = Map<String, dynamic>.from(params['RE'] as Map? ?? {});
    final le = Map<String, dynamic>.from(params['LE'] as Map? ?? {});
    return re.values.any((v) => v != null && v.toString().trim().isNotEmpty) ||
        le.values.any((v) => v != null && v.toString().trim().isNotEmpty);
  }
  return params.values.any((v) => v != null && v.toString().trim().isNotEmpty);
}

String _paramEye(Map<String, dynamic> params, String eye, String key) {
  final eyeMap = Map<String, dynamic>.from(params[eye] as Map? ?? {});
  final value = eyeMap[key] ??
      (key == 'power_mw' ? eyeMap['power'] : null) ??
      (key == 'duration_ms' ? eyeMap['duration'] : null) ??
      (key == 'spot_size_um' ? eyeMap['spot_size'] : null);
  if (value == null || value.toString().trim().isEmpty) return '-';
  return value.toString();
}

String _param(Map<String, dynamic> params, String key) {
  final value = params[key] ??
      (key == 'power_mw' ? params['power'] : null) ??
      (key == 'duration_ms' ? params['duration'] : null) ??
      (key == 'spot_size_um' ? params['spot_size'] : null);
  if (value == null || value.toString().trim().isEmpty) return '-';
  return value.toString();
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

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
            const SizedBox(height: 12),
            child,
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
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
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                right,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                left,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
