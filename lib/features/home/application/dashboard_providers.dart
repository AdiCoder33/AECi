import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logbook/data/entries_repository.dart';
import '../../logbook/domain/elog_entry.dart';
import '../../review/data/assignments_repository.dart';
import '../../submissions/data/logbook_submission_repository.dart';

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
  final submissionsRepo = ref.watch(logbookSubmissionRepositoryProvider);
  final submissions = await submissionsRepo.listSubmissionsForRecipient();
  final pending = submissions.length;
  final perTrainee = <String, int>{};
  for (final submission in submissions) {
    perTrainee[submission.createdBy] =
        (perTrainee[submission.createdBy] ?? 0) + 1;
  }

  final assignments = ref.watch(assignmentsRepositoryProvider);
  final trainees = await assignments.traineeIdsForConsultant();
  final entriesRepo = ref.watch(entriesRepositoryProvider);
  final all = <ElogEntry>[];
  for (final module in moduleTypes) {
    final list = await entriesRepo.listEntries(moduleType: module, onlyMine: false);
    all.addAll(list.where((e) => trainees.contains(e.createdBy)));
  }
  final approvalsThisMonth = all.where((e) {
    if (e.status != statusApproved) return false;
    final now = DateTime.now();
    return e.updatedAt.year == now.year && e.updatedAt.month == now.month;
  }).length;

  return ConsultantDashboardStats(
    pending: pending,
    approvalsThisMonth: approvalsThisMonth,
    perTrainee: perTrainee,
  );
});
