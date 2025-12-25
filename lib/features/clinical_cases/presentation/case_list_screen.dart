import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/clinical_cases_controller.dart';

class ClinicalCaseListScreen extends ConsumerWidget {
  const ClinicalCaseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cases = ref.watch(clinicalCaseListProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Clinical Cases'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_turned_in_outlined),
            onPressed: () => context.push('/cases/assessment-queue'),
            tooltip: 'Assessment Queue',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/cases/new'),
        backgroundColor: const Color(0xFF0B5FFF),
        elevation: 3,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Case',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: cases.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_information_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No cases yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap "New Case" to create your first clinical case',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  headingRowHeight: 42,
                  dataRowMinHeight: 48,
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Patient')),
                    DataColumn(label: Text('UID')),
                    DataColumn(label: Text('MR')),
                    DataColumn(label: Text('Diagnosis')),
                    DataColumn(label: Text('Updated')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: list.map((c) {
                    final updated = c.updatedAt?.toIso8601String().split('T').first ?? '-';
                    return DataRow(
                      onSelectChanged: (_) => context.push('/cases/${c.id}'),
                      cells: [
                        DataCell(Text(
                          c.dateOfExamination.toIso8601String().split('T').first,
                        )),
                        DataCell(Text(c.patientName)),
                        DataCell(Text(c.uidNumber)),
                        DataCell(Text(c.mrNumber)),
                        DataCell(Text(c.diagnosis)),
                        DataCell(Text(updated)),
                        DataCell(_StatusBadge(status: c.status)),
                      ],
                    );
                  }).toList(),
                ),
              ),
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
                'Failed to load cases',
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
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    Color color;
    switch (normalized) {
      case 'submitted':
        color = const Color(0xFF0B5FFF);
        break;
      case 'draft':
        color = const Color(0xFFF59E0B);
        break;
      default:
        color = const Color(0xFF64748B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        normalized.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
