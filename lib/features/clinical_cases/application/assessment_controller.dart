import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/assessment_repository.dart';
import '../../auth/application/auth_controller.dart';
import '../../community/data/community_repository.dart';
import '../../profile/data/profile_model.dart';

final caseAssessmentProvider = FutureProvider.family
    .autoDispose<CaseAssessment?, String>((ref, caseId) async {
  return ref.watch(assessmentRepositoryProvider).getAssessment(caseId);
});

final caseAssessmentRecipientsProvider = FutureProvider.family
    .autoDispose<List<AssessmentRecipient>, String>((ref, caseId) async {
  return ref.watch(assessmentRepositoryProvider).listRecipients(caseId);
});

final assessmentDoctorsProvider =
    FutureProvider.autoDispose<List<Profile>>((ref) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.listProfiles();
});

final assessmentQueueProvider =
    FutureProvider.autoDispose<List<AssessmentQueueItem>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  final uid = auth.session?.user.id;
  if (uid == null) return [];
  return ref.watch(assessmentRepositoryProvider).listAssignedQueue(uid);
});

final assessmentRosterProvider = FutureProvider.family
    .autoDispose<List<RosterConsultant>, ({String centre, String monthKey})>(
        (ref, query) async {
  return ref
      .watch(assessmentRepositoryProvider)
      .listRoster(centre: query.centre, monthKey: query.monthKey);
});

class AssessmentMutation extends StateNotifier<AsyncValue<void>> {
  AssessmentMutation(this._repo) : super(const AsyncValue.data(null));
  final AssessmentRepository _repo;

  Future<void> submitRecipients(String caseId, List<String> recipientIds) async {
    state = const AsyncValue.loading();
    try {
      await _repo.submitRecipients(
        caseId: caseId,
        recipientIds: recipientIds,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> complete(String assessmentId, String comments) async {
    state = const AsyncValue.loading();
    try {
      await _repo.consultantUpdate(
        assessmentId: assessmentId,
        status: 'completed',
        comments: comments,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final assessmentMutationProvider =
    StateNotifierProvider<AssessmentMutation, AsyncValue<void>>((ref) {
  return AssessmentMutation(ref.watch(assessmentRepositoryProvider));
});
