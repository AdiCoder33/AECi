// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logbook/data/entries_repository.dart';
import '../../logbook/domain/elog_entry.dart';
import '../../profile/application/profile_controller.dart';
import '../export_service.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  DateTime? _start;
  DateTime? _end;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Logbook')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select date range (optional)'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(context, true),
                    child: Text(
                      _start == null
                          ? 'Start date'
                          : _start!.toIso8601String().split('T').first,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(context, false),
                    child: Text(
                      _end == null
                          ? 'End date'
                          : _end!.toIso8601String().split('T').first,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isExporting) const LinearProgressIndicator(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isExporting ? null : () => _exportCsv(context),
              icon: const Icon(Icons.table_chart, color: Colors.black),
              label: const Text(
                'Export CSV',
                style: TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isExporting ? null : () => _exportPdf(context),
              icon: const Icon(Icons.picture_as_pdf, color: Colors.black),
              label: const Text(
                'Export PDF',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365 * 5)),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    await _export(context, asPdf: false);
  }

  Future<void> _exportPdf(BuildContext context) async {
    await _export(context, asPdf: true);
  }

  Future<void> _export(BuildContext context, {required bool asPdf}) async {
    setState(() => _isExporting = true);
    final entriesRepo = ref.read(entriesRepositoryProvider);
    final profile = ref.read(profileControllerProvider).profile;
    try {
      final all = <ElogEntry>[];
      for (final m in moduleTypes) {
        final list = await entriesRepo.listEntries(
          moduleType: m,
          onlyMine: true,
        );
        all.addAll(list);
      }
      final exporter = ExportService();
      if (asPdf) {
        final file = await exporter.exportPdf(
          entries: all,
          profile: profile,
          start: _start,
          end: _end,
        );
        await exporter.shareFile(file);
      } else {
        final file = await exporter.exportCsv(
          entries: all,
          start: _start,
          end: _end,
        );
        await exporter.shareFile(file);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(asPdf ? 'PDF exported' : 'CSV exported')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}
