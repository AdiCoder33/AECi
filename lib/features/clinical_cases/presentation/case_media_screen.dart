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
  const CaseMediaScreen({super.key, required this.caseId, this.readOnly = false});

  final String caseId;
  final bool readOnly;

  @override
  ConsumerState<CaseMediaScreen> createState() => _CaseMediaScreenState();
}

class _PendingMedia {
  final XFile file;
  final bool isVideo;
  String? eye;
  String note;

  _PendingMedia({
    required this.file,
    required this.isVideo,
    this.eye,
    this.note = '',
  });
}

class _CaseMediaScreenState extends ConsumerState<CaseMediaScreen> {
  final _noteController = TextEditingController();
  String _category = caseMediaCategories.first;
  String? _followupId;
  bool _uploading = false;
  final List<_PendingMedia> _pendingMedia = [];
  String? _selectedEye;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final followupsAsync = ref.watch(caseFollowupsProvider(widget.caseId));
    final mediaAsync = ref.watch(caseMediaProvider(widget.caseId));
    final isReadOnly = widget.readOnly;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Case Media',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          if (!isReadOnly) ...[
            // Upload Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Eye Selection and Category Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedEye,
                        decoration: InputDecoration(
                          labelText: 'Select Eye',
                          labelStyle: TextStyle(
                            color: _selectedEye != null ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                          prefixIcon: const Icon(
                            Icons.visibility_outlined,
                            color: Color(0xFF3B82F6),
                          ),
                          filled: true,
                          fillColor: _selectedEye != null 
                              ? const Color(0xFF3B82F6).withOpacity(0.05) 
                              : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF3B82F6),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _selectedEye != null 
                                  ? const Color(0xFF3B82F6) 
                                  : const Color(0xFFE2E8F0),
                              width: _selectedEye != null ? 2 : 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF3B82F6),
                              width: 2,
                            ),
                          ),
                        ),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'RE',
                            child: Text(
                              '👁️ Right Eye (RE)',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'LE',
                            child: Text(
                              '👁️ Left Eye (LE)',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'BOTH',
                            child: Text(
                              '👁️👁️ Both Eyes',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _selectedEye = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _category,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          labelStyle: const TextStyle(
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w600,
                          ),
                          prefixIcon: const Icon(
                            Icons.category_outlined,
                            color: Color(0xFF3B82F6),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF3B82F6).withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF3B82F6),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF3B82F6),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF3B82F6),
                              width: 2,
                            ),
                          ),
                        ),
                        isExpanded: true,
                        items: caseMediaCategories
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c.replaceAll('_', ' '),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _category = v ?? _category),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                followupsAsync.when(
                  data: (list) {
                    return DropdownButtonFormField<String?>(
                      value: _followupId,
                      decoration: InputDecoration(
                        labelText: 'Attach to follow-up (optional)',
                        labelStyle: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: const Icon(
                          Icons.calendar_today_outlined,
                          color: Color(0xFF3B82F6),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF3B82F6),
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF3B82F6),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF3B82F6),
                            width: 2,
                          ),
                        ),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text(
                            'Case level',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        ...list.map(
                          (f) => DropdownMenuItem(
                            value: f.id,
                            child: Text(
                              'Follow-up ${f.followupIndex}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
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
                  decoration: InputDecoration(
                    labelText: 'Optional note',
                    labelStyle: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: const Icon(
                      Icons.note_outlined,
                      color: Color(0xFF3B82F6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF3B82F6),
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF3B82F6),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF3B82F6),
                        width: 2,
                      ),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _uploading ? null : () => _pickMedia(false),
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('Add Image'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(
                            color: Color(0xFF3B82F6),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _uploading ? null : () => _pickMedia(true),
                        icon: const Icon(Icons.videocam_outlined),
                        label: const Text('Add Video'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(
                            color: Color(0xFF3B82F6),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                ],
              ),
            ),
            // Pending Media Preview
            if (_pendingMedia.isNotEmpty) ...[
              Container(
                color: const Color(0xFFFEF3C7),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.photo_library_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Selected Media',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => _pendingMedia.clear()),
                        icon: const Icon(
                          Icons.clear_all,
                          size: 18,
                        ),
                        label: const Text('Clear All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _pendingMedia.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final media = _pendingMedia[index];
                        return Stack(
                          children: [
                            Container(
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFF59E0B),
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: media.isVideo
                                    ? const Center(
                                        child: Icon(
                                          Icons.play_circle_fill,
                                          size: 48,
                                          color: Color(0xFF3B82F6),
                                        ),
                                      )
                                    : Image.file(
                                        File(media.file.path),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () => setState(() => _pendingMedia.removeAt(index)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                            if (media.eye != null)
                              Positioned(
                                bottom: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: media.eye == 'RE'
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF3B82F6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    media.eye!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _pendingMedia.isEmpty || _uploading
                          ? null
                          : _uploadAllMedia,
                      icon: _uploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_upload, color: Colors.white),
                      label: Text(_uploading ? 'Uploading...' : 'Submit All Media'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ],
            const Divider(height: 0),
          ],
          // Existing Media
          Expanded(
            child: mediaAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  if (_pendingMedia.isNotEmpty && !isReadOnly) {
                    return const SizedBox.shrink();
                  }
                  final emptySubtitle = isReadOnly
                      ? 'No media available for this case'
                      : 'Select an eye and tap Add Image or Add Video to get started';
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.photo_library_outlined,
                              size: 64,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No media uploaded yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            emptySubtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Group by eye - extract from note
                final reMedia = list.where((m) {
                  final note = m.note?.toLowerCase() ?? '';
                  return note.contains('eye: re)') || note.contains('eye: re');
                }).toList();
                
                final leMedia = list.where((m) {
                  final note = m.note?.toLowerCase() ?? '';
                  return note.contains('eye: le)') || note.contains('eye: le');
                }).toList();
                
                final bothMedia = list.where((m) {
                  final note = m.note?.toLowerCase() ?? '';
                  return note.contains('eye: both)') || note.contains('eye: both');
                }).toList();
                
                final otherMedia = list.where((m) {
                  final note = m.note?.toLowerCase() ?? '';
                  return !note.contains('eye: re)') && !note.contains('eye: re') &&
                         !note.contains('eye: le)') && !note.contains('eye: le') &&
                         !note.contains('eye: both)') && !note.contains('eye: both');
                }).toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (reMedia.isNotEmpty) ...[
                      _buildMediaSection(
                        'RIGHT EYE',
                        reMedia,
                        const Color(0xFF10B981),
                        readOnly: isReadOnly,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (leMedia.isNotEmpty) ...[
                      _buildMediaSection(
                        'LEFT EYE',
                        leMedia,
                        const Color(0xFF3B82F6),
                        readOnly: isReadOnly,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (bothMedia.isNotEmpty) ...[
                      _buildMediaSection(
                        'BOTH EYES',
                        bothMedia,
                        const Color(0xFF8B5CF6),
                        readOnly: isReadOnly,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (otherMedia.isNotEmpty)
                      _buildMediaSection(
                        'OTHER MEDIA',
                        otherMedia,
                        const Color(0xFF64748B),
                        readOnly: isReadOnly,
                      ),
                  ],
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

  Widget _buildMediaSection(
    String title,
    List<CaseMediaItem> items,
    Color color, {
    required bool readOnly,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.visibility_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${items.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) =>
                  _MediaTile(item: items[index], readOnly: readOnly),
            );
          },
        ),
      ],
    );
  }

  Future<void> _pickMedia(bool isVideo) async {
    if (_selectedEye == null) {
      _showError('Please select an eye first');
      return;
    }

    final picker = ImagePicker();
    XFile? file;
    try {
      if (isVideo) {
        file = await picker.pickVideo(source: ImageSource.gallery);
      } else {
        file = await picker.pickImage(source: ImageSource.gallery);
      }
    } catch (e) {
      _showError('Failed to pick media: ${e.toString()}');
      debugPrint('Pick media error: $e');
      return;
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

    setState(() {
      final pendingItem = _PendingMedia(
        file: file!,
        isVideo: isVideo,
        eye: _selectedEye,
        note: _noteController.text.trim(),
      );
      _pendingMedia.add(pendingItem);
      debugPrint('Added pending media: eye=${pendingItem.eye}, isVideo=$isVideo, path=${file.path}');
    });
  }

  Future<void> _uploadAllMedia() async {
    if (_pendingMedia.isEmpty) {
      _showError('No media selected');
      return;
    }

    setState(() => _uploading = true);
    
    int uploaded = 0;
    try {
      for (final media in _pendingMedia) {
        debugPrint('Uploading media ${uploaded + 1}/${_pendingMedia.length}');
        
        // Use the eye from pending media (captured at pick time)
        final eyeToUse = media.eye;
        if (eyeToUse == null) {
          throw Exception('Eye information missing for media');
        }
        
        // Don't append eye to category - database constraint doesn't allow it
        // Instead, include eye info in the note
        final noteWithEye = media.note.isEmpty
            ? 'Eye: $eyeToUse'
            : '${media.note} (Eye: $eyeToUse)';
        
        debugPrint('Category: $_category, MediaType: ${media.isVideo ? 'video' : 'image'}, Eye: $eyeToUse');
        debugPrint('File path: ${media.file.path}');
        
        // Create File from XFile path
        final file = File(media.file.path);
        
        // Check if file exists
        final exists = await file.exists();
        debugPrint('File exists: $exists');
        
        if (!exists) {
          throw Exception('File not found at: ${media.file.path}');
        }
        
        try {
          await ref.read(clinicalCasesRepositoryProvider).uploadMedia(
                caseId: widget.caseId,
                followupId: _followupId,
                category: _category, // Use category without eye suffix
                mediaType: media.isVideo ? 'video' : 'image',
                file: file,
                note: noteWithEye, // Include eye in note
              );
          
          uploaded++;
          debugPrint('Successfully uploaded $uploaded/${_pendingMedia.length}');
        } catch (uploadError) {
          debugPrint('Upload error for file: $uploadError');
          throw Exception('Failed to upload ${media.isVideo ? 'video' : 'image'}: ${uploadError.toString()}');
        }
      }
      
      if (mounted) {
        setState(() {
          _pendingMedia.clear();
          _noteController.clear();
          _uploading = false;
        });
        
        ref.invalidate(caseMediaProvider(widget.caseId));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully uploaded $uploaded ${uploaded == 1 ? 'file' : 'files'}!'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() => _uploading = false);
      }
      debugPrint('Upload error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Show more user-friendly error
      String errorMessage = e.toString();
      if (errorMessage.contains('storage')) {
        errorMessage = 'Storage error. Please check your internet connection.';
      } else if (errorMessage.contains('permission')) {
        errorMessage = 'Permission denied. Please check app permissions.';
      } else if (errorMessage.contains('File not found')) {
        errorMessage = 'Selected file no longer available.';
      } else if (errorMessage.contains('constraint') || errorMessage.contains('check')) {
        errorMessage = 'Invalid category selected. Please try again.';
      }
      
      _showError(errorMessage);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }
}

class _MediaTile extends ConsumerStatefulWidget {
  const _MediaTile({required this.item, this.readOnly = false});

  final CaseMediaItem item;
  final bool readOnly;

  @override
  ConsumerState<_MediaTile> createState() => _MediaTileState();
}

class _MediaTileState extends ConsumerState<_MediaTile> {
  bool _deleting = false;

  Future<void> _deleteMedia() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: const Text('Are you sure you want to delete this media file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await ref.read(clinicalCasesRepositoryProvider).deleteMedia(widget.item.id);
      if (mounted) {
        ref.invalidate(caseMediaProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Media deleted successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(clinicalCasesRepositoryProvider);
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FutureBuilder<String>(
                    future: repo.getSignedUrl(widget.item.storagePath),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.shade200,
                            ),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 32,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Failed to load',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      
                      final url = snapshot.data!;
                      if (widget.item.mediaType == 'video') {
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
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.red.shade50,
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: Colors.red,
                                      size: 32,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Image not found',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Category with icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        widget.item.mediaType == 'video' 
                            ? Icons.videocam 
                            : Icons.image,
                        size: 14,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.item.category.replaceAll('_', ' '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                // Media type badge
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: widget.item.mediaType == 'video'
                            ? const Color(0xFFEF4444).withOpacity(0.1)
                            : const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: widget.item.mediaType == 'video'
                              ? const Color(0xFFEF4444).withOpacity(0.3)
                              : const Color(0xFF10B981).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        widget.item.mediaType == 'video' ? 'VIDEO' : 'IMAGE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: widget.item.mediaType == 'video'
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (widget.item.followupId != null) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFF8B5CF6).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_repeat,
                              size: 9,
                              color: const Color(0xFF8B5CF6),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'FOLLOWUP',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF8B5CF6),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (widget.item.note != null && widget.item.note!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notes,
                          size: 12,
                          color: const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.item.note!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Delete button
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _deleting ? null : _deleteMedia,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _deleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
