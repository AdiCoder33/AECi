import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../application/clinical_cases_controller.dart';
import '../data/clinical_case_constants.dart';
import '../data/clinical_cases_repository.dart';

class CaseMediaScreen extends ConsumerStatefulWidget {
  const CaseMediaScreen({super.key, required this.caseId});

  final String caseId;

  @override
  ConsumerState<CaseMediaScreen> createState() => _CaseMediaScreenState();
}

class _CaseMediaScreenState extends ConsumerState<CaseMediaScreen> {
  final _noteController = TextEditingController();
  String _category = caseMediaCategories.first;
  String? _followupId;
  bool _uploading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final followupsAsync = ref.watch(caseFollowupsProvider(widget.caseId));
    final mediaAsync = ref.watch(caseMediaProvider(widget.caseId));

    return Scaffold(
      appBar: AppBar(title: const Text('Case Media')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Media category'),
                  items: caseMediaCategories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.replaceAll('_', ' ')),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v ?? _category),
                ),
                const SizedBox(height: 12),
                followupsAsync.when(
                  data: (list) {
                    return DropdownButtonFormField<String?>(
                      value: _followupId,
                      decoration: const InputDecoration(
                        labelText: 'Attach to follow-up (optional)',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Case level'),
                        ),
                        ...list.map(
                          (f) => DropdownMenuItem(
                            value: f.id,
                            child: Text('Follow-up ${f.followupIndex}'),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _followupId = v),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Failed to load follow-ups: $e'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Optional note',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _uploading ? null : () => _pick(false),
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('Pick Image'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _uploading ? null : () => _pick(true),
                        icon: _uploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.videocam, color: Colors.white),
                        label: const Text('Pick Video'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: mediaAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text('No media uploaded yet.'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    return _MediaTile(item: list[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(bool isVideo) async {
    final picker = ImagePicker();
    XFile? file;
    if (isVideo) {
      file = await picker.pickVideo(source: ImageSource.gallery);
    } else {
      file = await picker.pickImage(source: ImageSource.gallery);
    }
    if (file == null) return;

    final ext = p.extension(file.path).toLowerCase();
    final allowedImages = ['.jpg', '.jpeg', '.png'];
    final allowedVideos = ['.mp4', '.avi'];
    if (isVideo && !allowedVideos.contains(ext)) {
      _showError('Only MP4 or AVI videos are allowed.');
      return;
    }
    if (!isVideo && !allowedImages.contains(ext)) {
      _showError('Only JPEG or PNG images are allowed.');
      return;
    }

    setState(() => _uploading = true);
    try {
      await ref.read(clinicalCasesRepositoryProvider).uploadMedia(
            caseId: widget.caseId,
            followupId: _followupId,
            category: _category,
            mediaType: isVideo ? 'video' : 'image',
            file: File(file.path),
            note: _noteController.text.trim(),
          );
      _noteController.clear();
      ref.invalidate(caseMediaProvider(widget.caseId));
    } catch (e) {
      _showError('Upload failed: $e');
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }
}

class _MediaTile extends ConsumerWidget {
  const _MediaTile({required this.item});

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
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
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
