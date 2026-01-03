import 'package:flutter/material.dart';

import '../../domain/elog_entry.dart';

class EntryCard extends StatelessWidget {
  const EntryCard({super.key, required this.entry, this.onTap});

  final ElogEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final summary = _summaryText(entry);
    final keywordChips = entry.keywords.take(3).toList();
    final extra = entry.keywords.length - keywordChips.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 1,
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
              // Gradient Header
              Container(
                padding: const EdgeInsets.all(16),
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
                    // UID Badge
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.fingerprint,
                              size: 18,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                entry.patientUniqueId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Color(0xFF3B82F6),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // MRN Badge
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.badge_outlined,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                entry.mrn,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    _StatusBadge(status: entry.status),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (entry.keywords.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...keywordChips.map(
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
                          ),
                          if (extra > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '+$extra',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Updated ${_formatDate(entry.updatedAt)}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
