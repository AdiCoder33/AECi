import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/elog_entry.dart';
import '../../application/logbook_providers.dart';

class EntryCard extends ConsumerWidget {
  const EntryCard({super.key, required this.entry, this.onTap});

  final ElogEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = _summaryText(entry);
    final keywordChips = entry.keywords.take(3).toList();
    final extra = entry.keywords.length - keywordChips.length;
    final signedCache = ref.read(signedUrlCacheProvider.notifier);
    
    // Get image paths for atlas entries
    final imagePaths = entry.moduleType == moduleImages
        ? List<String>.from(entry.payload['uploadImagePaths'] ?? [])
        : <String>[];
    final imagePathsRE = entry.moduleType == moduleImages
        ? List<String>.from(entry.payload['uploadImagePathsRE'] ?? [])
        : <String>[];
    final imagePathsLE = entry.moduleType == moduleImages
        ? List<String>.from(entry.payload['uploadImagePathsLE'] ?? [])
        : <String>[];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Blue Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getModuleIcon(entry.moduleType),
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.patientUniqueId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.badge_outlined,
                                size: 12,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '# ${entry.mrn}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(status: entry.status),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Module Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getModuleIcon(entry.moduleType),
                            size: 10,
                            color: const Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getModuleName(entry.moduleType),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3B82F6),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Summary
                    Text(
                      summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.3,
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (entry.keywords.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...keywordChips.map(
                            (k) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.tag,
                                    size: 9,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    k,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (extra > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '+$extra',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    // Bottom Info Row
                    Row(
                      children: [
                        // Updated Time
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.schedule,
                                size: 11,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Updated ${_formatDate(entry.updatedAt)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Draft indicator if draft
                        if (entry.status == statusDraft) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFF59E0B).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_note,
                                  size: 10,
                                  color: const Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'DRAFT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFF59E0B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Image Preview for Atlas Entries - Larger and Clickable
                    if (imagePathsRE.isNotEmpty || imagePathsLE.isNotEmpty || imagePaths.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      // Description if available
                      if (entry.payload['briefDescription'] != null && 
                          entry.payload['briefDescription'].toString().isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 14,
                                color: const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  entry.payload['briefDescription'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF475569),
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      // Right Eye Images
                      if (imagePathsRE.isNotEmpty) ...[
                        Text(
                          'Right Eye',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 6),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: imagePathsRE.length == 1 ? 1 : 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: imagePathsRE.length > 4 ? 4 : imagePathsRE.length,
                          itemBuilder: (context, index) {
                            final path = imagePathsRE[index];
                            return FutureBuilder(
                              future: signedCache.getUrl(path),
                              builder: (context, snapshot) {
                                return InkWell(
                                  onTap: snapshot.hasData
                                      ? () => _showImageDialog(context, snapshot.data!)
                                      : null,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.green,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: snapshot.hasData
                                          ? Image.network(
                                              snapshot.data!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                color: const Color(0xFFF8FAFC),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    size: 40,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Container(
                                              color: const Color(0xFFF8FAFC),
                                              child: const Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Left Eye Images
                      if (imagePathsLE.isNotEmpty) ...[
                        Text(
                          'Left Eye',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 6),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: imagePathsLE.length == 1 ? 1 : 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: imagePathsLE.length > 4 ? 4 : imagePathsLE.length,
                          itemBuilder: (context, index) {
                            final path = imagePathsLE[index];
                            return FutureBuilder(
                              future: signedCache.getUrl(path),
                              builder: (context, snapshot) {
                                return InkWell(
                                  onTap: snapshot.hasData
                                      ? () => _showImageDialog(context, snapshot.data!)
                                      : null,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.blue,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: snapshot.hasData
                                          ? Image.network(
                                              snapshot.data!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                color: const Color(0xFFF8FAFC),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    size: 40,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Container(
                                              color: const Color(0xFFF8FAFC),
                                              child: const Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Old Images (backward compatibility)
                      if (imagePaths.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: imagePaths.length == 1 ? 1 : 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: imagePaths.length > 4 ? 4 : imagePaths.length,
                        itemBuilder: (context, index) {
                          final path = imagePaths[index];
                          return FutureBuilder(
                            future: signedCache.getUrl(path),
                            builder: (context, snapshot) {
                              return InkWell(
                                onTap: snapshot.hasData
                                    ? () => _showImageDialog(context, snapshot.data!)
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFF10B981),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        snapshot.hasData
                                            ? Image.network(
                                                snapshot.data!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(
                                                  color: const Color(0xFFF1F5F9),
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      size: 32,
                                                      color: Color(0xFF94A3B8),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                color: const Color(0xFFF1F5F9),
                                                child: const Center(
                                                  child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Color(0xFF10B981),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                        if (snapshot.hasData)
                                          Positioned(
                                            bottom: 4,
                                            right: 4,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.6),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.zoom_in,
                                                color: Colors.white,
                                                size: 14,
                                              ),
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
                      ),
                      if (imagePaths.length > 4)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '+${imagePaths.length - 4} more images • Tap to view all',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getModuleIcon(String moduleType) {
    switch (moduleType) {
      case moduleCases:
        return Icons.medical_information_rounded;
      case moduleImages:
        return Icons.photo_library_rounded;
      case moduleLearning:
        return Icons.school_rounded;
      case moduleRecords:
        return Icons.folder_special_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  String _getModuleName(String moduleType) {
    switch (moduleType) {
      case moduleCases:
        return 'CASE';
      case moduleImages:
        return 'ATLAS';
      case moduleLearning:
        return 'LEARNING';
      case moduleRecords:
        return 'RECORD';
      default:
        return 'ENTRY';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _summaryText(ElogEntry entry) {
    final payload = entry.payload;
    switch (entry.moduleType) {
      case moduleCases:
        return payload['briefDescription'] ?? 'Case';
      case moduleImages:
        return payload['diagnosis'] ??
            payload['briefDescription'] ??
            payload['keyDescriptionOrPathology'] ??
            'Image';
      case moduleLearning:
        return payload['stepName'] ??
            payload['teachingPoint'] ??
            payload['surgery'] ??
            'Learning';
      case moduleRecords:
        return payload['diagnosis'] ??
            payload['surgery'] ??
            payload['preOpDiagnosisOrPathology'] ??
            'Record';
      default:
        return '';
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 500,
            maxHeight: 500,
          ),
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Color(0xFF94A3B8),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  Color _backgroundColor() {
    switch (status) {
      case statusApproved:
        return const Color(0xFF10B981).withOpacity(0.1);
      case statusSubmitted:
        return const Color(0xFF0B5FFF).withOpacity(0.1);
      case statusNeedsRevision:
        return const Color(0xFFF59E0B).withOpacity(0.1);
      case statusRejected:
        return const Color(0xFFEF4444).withOpacity(0.1);
      default:
        return const Color(0xFF94A3B8).withOpacity(0.1);
    }
  }

  Color _textColor() {
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
        return Icons.check_circle_rounded;
      case statusSubmitted:
        return Icons.send_rounded;
      case statusNeedsRevision:
        return Icons.edit_note_rounded;
      case statusRejected:
        return Icons.cancel_rounded;
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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _textColor().withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon(),
            size: 14,
            color: _textColor(),
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _textColor(),
            ),
          ),
        ],
      ),
    );
  }
}
