import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../logbook/domain/elog_entry.dart';
import '../data/teaching_repository.dart';

final teachingListProvider =
    FutureProvider.autoDispose.family((ref, TeachingListParams params) async {
  final repo = ref.watch(teachingRepositoryProvider);
  return repo.listTeaching(
    module: params.module,
    scope: params.scope,
    centre: params.centre,
    keyword: params.keyword,
  );
});

class TeachingListParams {
  TeachingListParams({this.module, this.scope, this.centre, this.keyword});
  final String? module;
  final String? scope;
  final String? centre;
  final String? keyword;
}

final proposalListProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(teachingRepositoryProvider);
  return repo.listProposals();
});

class TeachingMutationController extends StateNotifier<AsyncValue<void>> {
  TeachingMutationController(this._repo) : super(const AsyncValue.data(null));
  final TeachingRepository _repo;

  Future<void> propose(String entryId, String note) async {
    state = const AsyncValue.loading();
    try {
      await _repo.propose(entryId, note);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<String> publish({
    required ElogEntry entry,
    required String title,
    required String summary,
    required String shareScope,
    required String centre,
  }) async {
    state = const AsyncValue.loading();
    try {
      final id = await _repo.publishFromEntry(
        entry: entry,
        title: title,
        summary: summary,
        shareScope: shareScope,
        centre: centre,
      );
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> reviewProposal(String id, String decision) async {
    state = const AsyncValue.loading();
    try {
      await _repo.reviewProposal(id, decision);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> bookmark(String itemId, bool add) async {
    await _repo.toggleBookmark(itemId, add);
  }
}

final teachingMutationProvider =
    StateNotifierProvider<TeachingMutationController, AsyncValue<void>>((ref) {
  final repo = ref.watch(teachingRepositoryProvider);
  return TeachingMutationController(repo);
});

final currentCentreProvider = Provider<String?>((ref) {
  final profile = ref.watch(authControllerProvider).session;
  return profile?.user.userMetadata?['centre'] as String?;
});
