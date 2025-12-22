import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/clinical_cases_repository.dart';

final clinicalCaseListProvider =
    FutureProvider.autoDispose<List<ClinicalCase>>((ref) async {
  final repo = ref.watch(clinicalCasesRepositoryProvider);
  return repo.listCases();
});

final clinicalCaseDetailProvider = FutureProvider.family
    .autoDispose<ClinicalCase, String>((ref, id) async {
  final repo = ref.watch(clinicalCasesRepositoryProvider);
  return repo.getCase(id);
});

class ClinicalCaseMutation extends StateNotifier<AsyncValue<void>> {
  ClinicalCaseMutation(this._repo) : super(const AsyncValue.data(null));
  final ClinicalCasesRepository _repo;

  Future<String> create(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final id = await _repo.createCase(data);
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateCase(id, data);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> addFollowup(String caseId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _repo.addFollowup(caseId, data);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final clinicalCaseMutationProvider =
    StateNotifierProvider<ClinicalCaseMutation, AsyncValue<void>>((ref) {
  return ClinicalCaseMutation(ref.watch(clinicalCasesRepositoryProvider));
});
