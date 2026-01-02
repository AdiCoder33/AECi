import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../clinical_cases/data/clinical_cases_repository.dart';
import '../../logbook/data/entries_repository.dart';
import '../../logbook/domain/elog_entry.dart';
import '../../portfolio/data/portfolio_repository.dart';
import '../data/logbook_submission_repository.dart';

class LogbookSubmissionController extends StateNotifier<AsyncValue<void>> {
  LogbookSubmissionController(this._repo)
      : super(const AsyncValue.data(null));

  final LogbookSubmissionRepository _repo;

  Future<String> submit({
    required List<String> moduleKeys,
    required List<String> recipientIds,
    required List<LogbookSubmissionItem> items,
  }) async {
    state = const AsyncValue.loading();
    try {
      final id = await _repo.submit(
        moduleKeys: moduleKeys,
        recipientIds: recipientIds,
        items: items,
      );
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final logbookSubmissionProvider =
    StateNotifierProvider<LogbookSubmissionController, AsyncValue<void>>(
        (ref) {
  return LogbookSubmissionController(
    ref.watch(logbookSubmissionRepositoryProvider),
  );
});

final submissionCasesProvider =
    FutureProvider.autoDispose<List<ClinicalCase>>((ref) async {
  final repo = ref.watch(clinicalCasesRepositoryProvider);
  return repo.listMyCases();
});

final submissionEntriesProvider =
    FutureProvider.family.autoDispose<List<ElogEntry>, String>(
        (ref, moduleType) async {
  final repo = ref.watch(entriesRepositoryProvider);
  return repo.listEntries(moduleType: moduleType, onlyMine: true);
});

final submissionPublicationsProvider =
    FutureProvider.autoDispose<List<PublicationItem>>((ref) async {
  final repo = ref.watch(portfolioRepositoryProvider);
  return repo.listPublications();
});
