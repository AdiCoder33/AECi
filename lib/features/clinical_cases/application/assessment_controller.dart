import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/assessment_repository.dart';

final caseAssessmentProvider = FutureProvider.family
    .autoDispose<CaseAssessment?, String>((ref, caseId) async {
  return ref.watch(assessmentRepositoryProvider).getAssessment(caseId);
});

class AssessmentMutation extends StateNotifier<AsyncValue<void>> {
  AssessmentMutation(this._repo) : super(const AsyncValue.data(null));
  final AssessmentRepository _repo;

  Future<void> submit(String caseId, String consultantId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.submitForAssessment(caseId: caseId, consultantId: consultantId);
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
