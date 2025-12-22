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
      appBar: AppBar(title: const Text('Clinical Cases')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/cases/new'),
        child: const Icon(Icons.add),
      ),
      body: cases.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No cases yet'));
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Patient')),
                DataColumn(label: Text('UID')),
                DataColumn(label: Text('MR')),
                DataColumn(label: Text('Diagnosis')),
                DataColumn(label: Text('Updated')),
              ],
              rows: list
                  .map(
                    (c) => DataRow(
                      cells: [
                        DataCell(Text(c.dateOfExamination.toIso8601String().split('T').first)),
                        DataCell(Text(c.patientName)),
                        DataCell(Text(c.uidNumber)),
                        DataCell(Text(c.mrNumber)),
                        DataCell(Text(c.diagnosis)),
                        DataCell(Text(c.updatedAt?.toLocal().toString() ?? '')),
                      ],
                      onSelectChanged: (_) => context.push('/cases/${c.id}'),
                    ),
                  )
                  .toList(),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
