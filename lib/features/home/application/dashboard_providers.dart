import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logbook/data/entries_repository.dart';
import '../../logbook/domain/elog_entry.dart';
import '../../review/data/assignments_repository.dart';

class FellowDashboardStats {
  FellowDashboardStats({
    required this.statusCounts,
    required this.moduleCounts,
  });

  final Map<String, int> statusCounts;
  final Map<String, int> moduleCounts;

  int get drafts => statusCounts[statusDraft] ?? 0;
  int get submitted => statusCounts[statusSubmitted] ?? 0;
  int get approved => statusCounts[statusApproved] ?? 0;
}

class ConsultantDashboardStats {
  ConsultantDashboardStats({
    required this.pending,
    required this.approvalsThisMonth,
    required this.perTrainee,
  });

  final int pending;
  final int approvalsThisMonth;
  final Map<String, int> perTrainee;
}

final fellowDashboardProvider =
    FutureProvider<FellowDashboardStats>((ref) async {
  final repo = ref.watch(entriesRepositoryProvider);
  final statusCounts = <String, int>{};
  final moduleCounts = <String, int>{};
  for (final module in moduleTypes) {
    final entries = await repo.listEntries(moduleType: module, onlyMine: true);
    moduleCounts[module] = entries.length;
    for (final e in entries) {
      statusCounts[e.status] = (statusCounts[e.status] ?? 0) + 1;
    }
  }
  return FellowDashboardStats(
    statusCounts: statusCounts,
    moduleCounts: moduleCounts,
  );
});

final consultantDashboardProvider =
    FutureProvider<ConsultantDashboardStats>((ref) async {
  final assignments = ref.watch(assignmentsRepositoryProvider);
  final trainees = await assignments.traineeIdsForConsultant();
  if (trainees.isEmpty) {
    return ConsultantDashboardStats(
      pending: 0,
      approvalsThisMonth: 0,
      perTrainee: {},
    );
  }
  final repo = ref.watch(entriesRepositoryProvider);
  final all = <ElogEntry>[];
  for (final module in moduleTypes) {
    final list = await repo.listEntries(moduleType: module, onlyMine: false);
    all.addAll(list.where((e) => trainees.contains(e.createdBy)));
  }
  final pending = all.where((e) => e.status == statusSubmitted).length;
  final approvalsThisMonth = all.where((e) {
    if (e.status != statusApproved) return false;
    final now = DateTime.now();
    return e.updatedAt.year == now.year && e.updatedAt.month == now.month;
  }).length;
  final perTrainee = <String, int>{};
  for (final e in all) {
    perTrainee[e.createdBy] = (perTrainee[e.createdBy] ?? 0) + 1;
  }
  return ConsultantDashboardStats(
    pending: pending,
    approvalsThisMonth: approvalsThisMonth,
    perTrainee: perTrainee,
  );
});
