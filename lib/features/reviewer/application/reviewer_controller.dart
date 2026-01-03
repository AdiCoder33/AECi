import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reviewer_repository.dart';

final reviewerPendingProvider =
    FutureProvider.autoDispose<List<ReviewItem>>((ref) async {
  return ref.watch(reviewerRepositoryProvider).listPendingItems();
});

final reviewerReviewedProvider =
    FutureProvider.autoDispose<List<ReviewedItem>>((ref) async {
  return ref.watch(reviewerRepositoryProvider).listReviewedItems();
});

final reviewerCaseAssessmentProvider =
    FutureProvider.family.autoDispose<ReviewerAssessment?, String>(
        (ref, caseId) async {
  return ref
      .watch(reviewerRepositoryProvider)
      .getMyClinicalCaseAssessment(caseId);
});

final reviewerEntryAssessmentProvider =
    FutureProvider.family.autoDispose<ReviewerAssessment?, String>(
        (ref, entryId) async {
  return ref
      .watch(reviewerRepositoryProvider)
      .getMyElogEntryAssessment(entryId);
});

class ReviewerMutation extends StateNotifier<AsyncValue<void>> {
  ReviewerMutation(this._repo) : super(const AsyncValue.data(null));

  final ReviewerRepository _repo;

  Future<void> submitClinicalCase({
    required String caseId,
    required String traineeId,
    required int score,
    required String remarks,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.submitClinicalCaseReview(
        caseId: caseId,
        traineeId: traineeId,
        score: score,
        remarks: remarks,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> submitElogEntryScore({
    required String entryId,
    required String traineeId,
    required int score,
    required String remarks,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.submitElogEntryScore(
        entryId: entryId,
        traineeId: traineeId,
        score: score,
        remarks: remarks,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> submitElogEntryStepScore({
    required String entryId,
    required String traineeId,
    required List<Map<String, dynamic>> stepScores,
    required int totalScore,
    required String remarks,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.submitElogEntryStepScore(
        entryId: entryId,
        traineeId: traineeId,
        stepScores: stepScores,
        totalScore: totalScore,
        remarks: remarks,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> submitSurgicalVideo({
    required String entryId,
    required String traineeId,
    required List<Map<String, dynamic>> oscarScores,
    required int totalScore,
    required String remarks,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.submitSurgicalVideoReview(
        entryId: entryId,
        traineeId: traineeId,
        oscarScores: oscarScores,
        totalScore: totalScore,
        remarks: remarks,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final reviewerMutationProvider =
    StateNotifierProvider<ReviewerMutation, AsyncValue<void>>((ref) {
  return ReviewerMutation(ref.watch(reviewerRepositoryProvider));
});
