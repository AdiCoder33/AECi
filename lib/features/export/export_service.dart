import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../logbook/domain/elog_entry.dart';
import '../profile/data/profile_model.dart';

class ExportService {
  Future<File> exportCsv({
    required List<ElogEntry> entries,
    required DateTime? start,
    required DateTime? end,
  }) async {
    final rows = <List<String>>[];
    rows.add([
      'module_type',
      'created_at',
      'patient_unique_id',
      'mrn',
      'keywords',
      'summary',
      'video_link',
    ]);
    for (final e in entries) {
      if (start != null && e.createdAt.isBefore(start)) continue;
      if (end != null && e.createdAt.isAfter(end)) continue;
      final summary = _primaryField(e);
      final video = (e.payload['surgicalVideoLink'] ?? '').toString();
      rows.add([
        e.moduleType,
        e.createdAt.toIso8601String(),
        e.patientUniqueId,
        e.mrn,
        e.keywords.join('|'),
        summary,
        video,
      ]);
    }
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/elogbook_export.csv');
    await file.writeAsString(csv);
    return file;
  }

  Future<File> exportPdf({
    required List<ElogEntry> entries,
    required Profile? profile,
    required DateTime? start,
    required DateTime? end,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) {
          return [
            pw.Text('Aravind E-Logbook', style: pw.TextStyle(fontSize: 20)),
            if (profile != null) ...[
              pw.Text(
                '${profile.name} • ${profile.designation} • ${profile.centre} • ${profile.employeeId}',
              ),
              pw.SizedBox(height: 12),
            ],
            ...moduleTypes.map((m) {
              final list = entries.where((e) {
                if (e.moduleType != m) return false;
                if (start != null && e.createdAt.isBefore(start)) return false;
                if (end != null && e.createdAt.isAfter(end)) return false;
                return true;
              }).toList();
              if (list.isEmpty) return pw.Container();
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 10),
                  pw.Text(
                    m.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Divider(),
                  ...list.map((e) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '${e.patientUniqueId} • MRN ${e.mrn} • ${e.createdAt.toIso8601String()}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(_primaryField(e)),
                          if ((e.payload['surgicalVideoLink'] ?? '')
                              .toString()
                              .isNotEmpty)
                            pw.Text(
                              'Video: ${e.payload['surgicalVideoLink']}',
                              style: pw.TextStyle(fontSize: 10),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            }),
          ];
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/elogbook_portfolio.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  Future<void> shareFile(File file) async {
    await Share.shareXFiles([XFile(file.path)]);
  }

  String _primaryField(ElogEntry e) {
    final p = e.payload;
    switch (e.moduleType) {
      case moduleCases:
        return (p['briefDescription'] ?? '').toString();
      case moduleImages:
        return (p['keyDescriptionOrPathology'] ?? '').toString();
      case moduleLearning:
        return (p['teachingPoint'] ?? '').toString();
      case moduleRecords:
        return (p['learningPointOrComplication'] ??
                p['preOpDiagnosisOrPathology'] ??
                '')
            .toString();
      default:
        return '';
    }
  }
}
