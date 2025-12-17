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

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  entry.patientUniqueId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'MRN: ${entry.mrn}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.orange.withValues(alpha: 0.15),
                  ),
                  child: Text(
                    entry.status,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...keywordChips.map(
                  (k) => Chip(
                    label: Text(k),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                if (extra > 0)
                  Chip(
                    label: Text('+$extra'),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Updated: ${entry.updatedAt.toLocal()}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _summaryText(ElogEntry entry) {
    final payload = entry.payload;
    switch (entry.moduleType) {
      case moduleCases:
        return payload['briefDescription'] ?? 'Case';
      case moduleImages:
        return payload['keyDescriptionOrPathology'] ?? 'Image';
      case moduleLearning:
        return payload['teachingPoint'] ?? 'Learning';
      case moduleRecords:
        return payload['preOpDiagnosisOrPathology'] ?? 'Record';
      default:
        return '';
    }
  }
}
