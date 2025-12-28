import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/clinical_cases_controller.dart';

// Providers for search/filter state
final caseSearchTextProvider = StateProvider<String>((ref) => '');
final caseStatusFilterProvider = StateProvider<String>((ref) => 'All');

class ClinicalCaseListScreen extends ConsumerWidget {
  const ClinicalCaseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cases = ref.watch(clinicalCaseListProvider);
    final searchText = ref.watch(caseSearchTextProvider);
    final selectedStatus = ref.watch(caseStatusFilterProvider);
    final searchController = TextEditingController(text: searchText);
    final List<String> statusFilters = ['All', 'Draft', 'Submitted'];

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
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Case',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, UID, MR, diagnosis...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                ref.read(caseSearchTextProvider.notifier).state = value
                    .trim()
                    .toLowerCase();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Row(
              children: statusFilters.map((status) {
                final isSelected = selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(caseStatusFilterProvider.notifier).state =
                          status;
                    },
                    selectedColor: const Color(0xFF0B5FFF),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF0B5FFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: cases.when(
              data: (list) {
                // Filter by status
                List filtered = selectedStatus == 'All'
                    ? list
                    : list
                          .where(
                            (c) =>
                                c.status.toLowerCase() ==
                                selectedStatus.toLowerCase(),
                          )
                          .toList();
                // Filter by search
                if (searchText.isNotEmpty) {
                  filtered = filtered
                      .where(
                        (c) =>
                            c.patientName.toLowerCase().contains(searchText) ||
                            c.uidNumber.toLowerCase().contains(searchText) ||
                            c.mrNumber.toLowerCase().contains(searchText) ||
                            c.diagnosis.toLowerCase().contains(searchText),
                      )
                      .toList();
                }
                if (filtered.isEmpty) {
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
                          'No cases found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Try a different search or filter',
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
                return ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    final updated =
                        c.updatedAt?.toIso8601String().split('T').first ?? '-';
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      elevation: 4,
                      shadowColor: Colors.black12,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => context.push('/cases/${c.id}'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 22,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(
                                  0xFF0B5FFF,
                                ).withOpacity(0.08),
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF0B5FFF),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          c.patientName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF0B172A),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        _StatusBadge(status: c.status),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'UID: ${c.uidNumber}   MR: ${c.mrNumber}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Diagnosis: ${c.diagnosis}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF0B5FFF),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: Color(0xFF94A3B8),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          c.dateOfExamination
                                              .toIso8601String()
                                              .split('T')
                                              .first,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.update,
                                          size: 14,
                                          color: Color(0xFF94A3B8),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          updated,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF0B5FFF),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF0B5FFF)),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
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
          ),
        ],
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
