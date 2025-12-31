import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/clinical_cases_controller.dart';

// Providers for search/filter state
final caseSearchTextProvider = StateProvider<String>((ref) => '');
final caseStatusFilterProvider = StateProvider<String>((ref) => 'All');

class ClinicalCaseListScreen extends ConsumerStatefulWidget {
  const ClinicalCaseListScreen({super.key});

  @override
  ConsumerState<ClinicalCaseListScreen> createState() =>
      _ClinicalCaseListScreenState();
}

class _ClinicalCaseListScreenState
    extends ConsumerState<ClinicalCaseListScreen> {
  late final TextEditingController searchController;
  final List<String> statusFilters = ['All', 'Draft', 'Submitted'];

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController(
      text: ref.read(caseSearchTextProvider),
    );
    searchController.addListener(() {
      final value = searchController.text.trim().toLowerCase();
      if (ref.read(caseSearchTextProvider) != value) {
        ref.read(caseSearchTextProvider.notifier).state = value;
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cases = ref.watch(clinicalCaseListProvider);
    final searchText = ref.watch(caseSearchTextProvider);
    final selectedStatus = ref.watch(caseStatusFilterProvider);
    // Keep controller in sync if provider changes externally
    if (searchController.text != searchText) {
      searchController.value = searchController.value.copyWith(
        text: searchText,
        selection: TextSelection.collapsed(offset: searchText.length),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Clinical Cases',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0B172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.assignment_turned_in_outlined,
              color: Color(0xFF0B5FFF),
            ),
            onPressed: () => context.push('/cases/assessment-queue'),
            tooltip: 'Assessment Queue',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/cases/new'),
        backgroundColor: const Color(0xFF0B5FFF),
        elevation: 6,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Case',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: 0.2,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: TextField(
              controller: searchController,
              style: const TextStyle(fontSize: 16, color: Color(0xFF0B172A)),
              decoration: InputDecoration(
                hintText: 'Search by name, UID, MR, diagnosis...',
                hintStyle: const TextStyle(color: Color(0xFFB6C2D2)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0B5FFF)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE5EAF2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF0B5FFF),
                    width: 1.5,
                  ),
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
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(
                      status,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(caseStatusFilterProvider.notifier).state =
                          status;
                    },
                    selectedColor: const Color(0xFF0B5FFF),
                    backgroundColor: const Color(0xFFE5EAF2),
                    elevation: isSelected ? 4 : 0,
                    pressElevation: 6,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF0B5FFF),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 18),
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    final updated =
                        c.updatedAt?.toIso8601String().split('T').first ?? '-';
                    // Set card color based on status
                    Color cardColor;
                    Color shadowColor;
                    switch (c.status.toLowerCase()) {
                      case 'submitted':
                        cardColor = const Color(0xFFEAF2FF); // light blue
                        shadowColor = const Color(0xFF0B5FFF).withOpacity(0.13);
                        break;
                      case 'draft':
                        cardColor = const Color(0xFFFFF7E6); // light yellow
                        shadowColor = const Color(0xFFF59E0B).withOpacity(0.13);
                        break;
                      default:
                        cardColor = Colors.white;
                        shadowColor = const Color(0xFF0B5FFF).withOpacity(0.10);
                    }
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: Material(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(22),
                        elevation: 6,
                        shadowColor: shadowColor,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () => context.push('/cases/${c.id}'),
                          splashColor: const Color(
                            0xFF0B5FFF,
                          ).withOpacity(0.08),
                          highlightColor: Colors.transparent,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 22,
                              horizontal: 20,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(
                                          0xFF0B5FFF,
                                        ).withOpacity(0.18),
                                        const Color(
                                          0xFF0B5FFF,
                                        ).withOpacity(0.08),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Color(0xFF0B5FFF),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              c.patientName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                                color: Color(0xFF0B172A),
                                                letterSpacing: 0.1,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          _StatusBadge(status: c.status),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'UID: ${c.uidNumber}   MR: ${c.mrNumber}',
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          color: Color(0xFF64748B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Diagnosis: ${c.diagnosis}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF0B5FFF),
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 15,
                                            color: Color(0xFFB6C2D2),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            c.dateOfExamination
                                                .toIso8601String()
                                                .split('T')
                                                .first,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Icon(
                                            Icons.update,
                                            size: 15,
                                            color: Color(0xFFB6C2D2),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            updated,
                                            style: const TextStyle(
                                              fontSize: 12.5,
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
                                  size: 28,
                                ),
                              ],
                            ),
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
    Color bg;
    switch (normalized) {
      case 'submitted':
        color = const Color(0xFF0B5FFF);
        bg = const Color(0xFF0B5FFF).withOpacity(0.13);
        break;
      case 'draft':
        color = const Color(0xFFF59E0B);
        bg = const Color(0xFFF59E0B).withOpacity(0.13);
        break;
      default:
        color = const Color(0xFF64748B);
        bg = const Color(0xFF64748B).withOpacity(0.13);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        normalized.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
