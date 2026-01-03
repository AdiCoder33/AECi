import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase_client.dart';
import '../../clinical_cases/data/clinical_cases_repository.dart';
import '../../community/data/community_repository.dart';
import '../../logbook/data/entries_repository.dart';
import '../../logbook/domain/logbook_sections.dart';
import '../../portfolio/data/portfolio_repository.dart';
import '../../profile/data/profile_model.dart';
import '../../submissions/data/logbook_submission_repository.dart';

class TraineeAssessmentGroup {
  TraineeAssessmentGroup({
    required this.profile,
    required this.count,
  });

  final Profile profile;
  final int count;
}

class SubmissionItemDetail {
  SubmissionItemDetail({
    required this.entityType,
    required this.entityId,
    required this.moduleKey,
    required this.moduleLabel,
    required this.title,
    required this.subtitle,
    required this.updatedAt,
  });

  final String entityType;
  final String entityId;
  final String moduleKey;
  final String moduleLabel;
  final String title;
  final String subtitle;
  final DateTime updatedAt;
}

final consultantPendingProfilesProvider =
    FutureProvider.autoDispose<List<TraineeAssessmentGroup>>((ref) async {
  final submissionsRepo = ref.watch(logbookSubmissionRepositoryProvider);
  final communityRepo = ref.watch(communityRepositoryProvider);

  final submissions = await submissionsRepo.listSubmissionsForRecipient();
  if (submissions.isEmpty) return [];

  final counts = <String, int>{};
  for (final submission in submissions) {
    counts[submission.createdBy] = (counts[submission.createdBy] ?? 0) + 1;
  }
  return _buildGroupsFromCounts(communityRepo, counts);
});

final consultantReviewedProfilesProvider =
    FutureProvider.autoDispose<List<TraineeAssessmentGroup>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final reviewerId = client.auth.currentUser?.id;
  if (reviewerId == null) return [];

  final entriesRepo = ref.watch(entriesRepositoryProvider);
  final communityRepo = ref.watch(communityRepositoryProvider);

  final entries = await entriesRepo.listEntriesReviewedBy(reviewerId);
  if (entries.isEmpty) return [];

  final counts = <String, int>{};
  for (final entry in entries) {
    counts[entry.createdBy] = (counts[entry.createdBy] ?? 0) + 1;
  }
  return _buildGroupsFromCounts(communityRepo, counts);
});

final traineeSubmissionItemsProvider =
    FutureProvider.family.autoDispose<List<SubmissionItemDetail>, String>((
  ref,
  traineeId,
) async {
  final submissionsRepo = ref.watch(logbookSubmissionRepositoryProvider);
  final submissions = await submissionsRepo.listSubmissionsForRecipient();
  if (submissions.isEmpty) return [];

  final traineeSubmissions =
      submissions.where((s) => s.createdBy == traineeId).toList();
  if (traineeSubmissions.isEmpty) return [];

  final submissionIds = traineeSubmissions.map((s) => s.id).toList();
  final items = await submissionsRepo.listSubmissionItems(submissionIds);
  if (items.isEmpty) return [];

  final entryIds = <String>{};
  final caseIds = <String>{};
  final publicationIds = <String>{};
  for (final item in items) {
    switch (item.entityType) {
      case 'elog_entry':
        entryIds.add(item.entityId);
        break;
      case 'clinical_case':
        caseIds.add(item.entityId);
        break;
      case 'publication':
        publicationIds.add(item.entityId);
        break;
    }
  }

  final entriesRepo = ref.watch(entriesRepositoryProvider);
  final casesRepo = ref.watch(clinicalCasesRepositoryProvider);
  final portfolioRepo = ref.watch(portfolioRepositoryProvider);

  final entries = await entriesRepo.listEntriesByIds(entryIds.toList());
  final cases = await casesRepo.listCasesByIds(caseIds.toList());
  final publications =
      await portfolioRepo.listPublicationsByIds(publicationIds.toList());

  final entryMap = {for (final entry in entries) entry.id: entry};
  final caseMap = {for (final c in cases) c.id: c};
  final publicationMap = {for (final p in publications) p.id: p};

  final sectionLabels = {
    for (final section in logbookSections) section.key: section.label,
  };

  final details = <SubmissionItemDetail>[];
  for (final item in items) {
    final moduleLabel = sectionLabels[item.moduleKey] ?? item.moduleKey;
    switch (item.entityType) {
      case 'elog_entry':
        final entry = entryMap[item.entityId];
        details.add(
          SubmissionItemDetail(
            entityType: item.entityType,
            entityId: item.entityId,
            moduleKey: item.moduleKey,
            moduleLabel: moduleLabel,
            title: entry?.patientUniqueId ?? 'Logbook entry',
            subtitle: entry == null
                ? 'Entry ${item.entityId}'
                : 'MRN ${entry.mrn} | ${entry.moduleType}',
            updatedAt: entry?.updatedAt ?? entry?.createdAt ?? item.createdAt,
          ),
        );
        break;
      case 'clinical_case':
        final clinicalCase = caseMap[item.entityId];
        details.add(
          SubmissionItemDetail(
            entityType: item.entityType,
            entityId: item.entityId,
            moduleKey: item.moduleKey,
            moduleLabel: moduleLabel,
            title: clinicalCase?.patientName ?? 'Case',
            subtitle: clinicalCase == null
                ? 'Case ${item.entityId}'
                : 'UID ${clinicalCase.uidNumber} | MR ${clinicalCase.mrNumber}',
            updatedAt: clinicalCase?.updatedAt ??
                clinicalCase?.dateOfExamination ??
                item.createdAt,
          ),
        );
        break;
      case 'publication':
        final publication = publicationMap[item.entityId];
        details.add(
          SubmissionItemDetail(
            entityType: item.entityType,
            entityId: item.entityId,
            moduleKey: item.moduleKey,
            moduleLabel: moduleLabel,
            title: publication?.title ?? 'Publication',
            subtitle: publication == null
                ? 'Publication ${item.entityId}'
                : publication.type,
            updatedAt: publication?.updatedAt ?? item.createdAt,
          ),
        );
        break;
      default:
        details.add(
          SubmissionItemDetail(
            entityType: item.entityType,
            entityId: item.entityId,
            moduleKey: item.moduleKey,
            moduleLabel: moduleLabel,
            title: 'Submitted item',
            subtitle: item.entityId,
            updatedAt: item.createdAt,
          ),
        );
    }
  }

  details.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return details;
});

Future<List<TraineeAssessmentGroup>> _buildGroupsFromCounts(
  CommunityRepository communityRepo,
  Map<String, int> counts,
) async {
  if (counts.isEmpty) return [];

  final profiles = await communityRepo.listProfilesByIds(
    counts.keys.toList(),
  );
  if (profiles.isEmpty) return [];

  final profileMap = {
    for (final profile in profiles) profile.id: profile,
  };

  final groups = <TraineeAssessmentGroup>[];
  for (final entry in counts.entries) {
    final profile = profileMap[entry.key];
    if (profile == null) continue;
    groups.add(
      TraineeAssessmentGroup(
        profile: profile,
        count: entry.value,
      ),
    );
  }
  groups.sort((a, b) => a.profile.name.compareTo(b.profile.name));
  return groups;
}
