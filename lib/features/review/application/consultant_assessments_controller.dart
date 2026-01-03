import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase_client.dart';
import '../../community/data/community_repository.dart';
import '../../logbook/data/entries_repository.dart';
import '../../logbook/domain/elog_entry.dart';
import '../../profile/data/profile_model.dart';
import '../data/assignments_repository.dart';

class TraineeAssessmentGroup {
  TraineeAssessmentGroup({
    required this.profile,
    required this.entries,
  });

  final Profile profile;
  final List<ElogEntry> entries;

  int get count => entries.length;
}

const _submittedStatuses = [
  statusSubmitted,
  statusApproved,
  statusNeedsRevision,
  statusRejected,
];

final consultantPendingProfilesProvider =
    FutureProvider.autoDispose<List<TraineeAssessmentGroup>>((ref) async {
  final assignmentsRepo = ref.watch(assignmentsRepositoryProvider);
  final entriesRepo = ref.watch(entriesRepositoryProvider);
  final communityRepo = ref.watch(communityRepositoryProvider);

  final traineeIds = await assignmentsRepo.traineeIdsForConsultant();
  if (traineeIds.isEmpty) return [];

  final entries = await entriesRepo.listEntriesForTrainees(
    traineeIds: traineeIds,
    statuses: [statusSubmitted],
  );
  return _buildGroups(communityRepo, entries);
});

final consultantReviewedProfilesProvider =
    FutureProvider.autoDispose<List<TraineeAssessmentGroup>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final reviewerId = client.auth.currentUser?.id;
  if (reviewerId == null) return [];

  final assignmentsRepo = ref.watch(assignmentsRepositoryProvider);
  final entriesRepo = ref.watch(entriesRepositoryProvider);
  final communityRepo = ref.watch(communityRepositoryProvider);

  final traineeIds = await assignmentsRepo.traineeIdsForConsultant();
  if (traineeIds.isEmpty) return [];

  final entries = await entriesRepo.listEntriesForTrainees(
    traineeIds: traineeIds,
    reviewedBy: reviewerId,
  );
  return _buildGroups(communityRepo, entries);
});

final traineeSubmittedEntriesProvider =
    FutureProvider.family.autoDispose<List<ElogEntry>, String>((ref, traineeId) {
  final entriesRepo = ref.watch(entriesRepositoryProvider);
  return entriesRepo.listEntriesForTrainees(
    traineeIds: [traineeId],
    statuses: _submittedStatuses,
  );
});

Future<List<TraineeAssessmentGroup>> _buildGroups(
  CommunityRepository communityRepo,
  List<ElogEntry> entries,
) async {
  if (entries.isEmpty) return [];

  final byTrainee = <String, List<ElogEntry>>{};
  for (final entry in entries) {
    byTrainee.putIfAbsent(entry.createdBy, () => []).add(entry);
  }
  for (final list in byTrainee.values) {
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  final profiles = await communityRepo.listProfilesByIds(
    byTrainee.keys.toList(),
  );
  if (profiles.isEmpty) return [];

  final profileMap = {
    for (final profile in profiles) profile.id: profile,
  };

  final groups = <TraineeAssessmentGroup>[];
  for (final entry in byTrainee.entries) {
    final profile = profileMap[entry.key];
    if (profile == null) continue;
    groups.add(TraineeAssessmentGroup(profile: profile, entries: entry.value));
  }
  groups.sort((a, b) => a.profile.name.compareTo(b.profile.name));
  return groups;
}
