import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logbook/data/entries_repository.dart';
import '../../logbook/domain/elog_entry.dart';
import '../data/assignments_repository.dart';
import '../data/reviews_repository.dart';

class ReviewQueueState {
  const ReviewQueueState({
    required this.entries,
    required this.isLoading,
    required this.error,
  });

  final List<ElogEntry> entries;
  final bool isLoading;
  final String? error;

  factory ReviewQueueState.initial() =>
      const ReviewQueueState(entries: [], isLoading: false, error: null);
}

class ReviewController extends StateNotifier<ReviewQueueState> {
  ReviewController(
    this._entriesRepo,
    this._assignmentsRepo,
    this._reviewsRepo,
  ) : super(ReviewQueueState.initial());

  final EntriesRepository _entriesRepo;
  final AssignmentsRepository _assignmentsRepo;
  final ReviewsRepository _reviewsRepo;

  Future<void> loadQueue({String? module}) async {
    state = ReviewQueueState(entries: state.entries, isLoading: true, error: null);
    try {
      final trainees = await _assignmentsRepo.traineeIdsForConsultant();
      final fetched = <ElogEntry>[];
      for (final m in moduleTypes) {
        if (module != null && module != m) continue;
        final list = await _entriesRepo.listEntries(
          moduleType: m,
          onlyMine: false,
        );
        fetched.addAll(
          list.where(
            (e) =>
                e.status == statusSubmitted &&
                trainees.contains(e.createdBy),
          ),
        );
      }
      state = ReviewQueueState(entries: fetched, isLoading: false, error: null);
    } catch (e) {
      state = ReviewQueueState(entries: [], isLoading: false, error: e.toString());
    }
  }

  Future<void> review({
    required String entryId,
    required String decision,
    required String comment,
    required List<String> requiredChanges,
  }) async {
    await _reviewsRepo.submitReview(
      entryId: entryId,
      decision: decision,
      comment: comment,
      requiredChanges: requiredChanges,
    );
  }
}

final reviewControllerProvider =
    StateNotifierProvider<ReviewController, ReviewQueueState>((ref) {
  final entriesRepo = ref.watch(entriesRepositoryProvider);
  final assignmentsRepo = ref.watch(assignmentsRepositoryProvider);
  final reviewsRepo = ref.watch(reviewsRepositoryProvider);
  return ReviewController(entriesRepo, assignmentsRepo, reviewsRepo);
});
