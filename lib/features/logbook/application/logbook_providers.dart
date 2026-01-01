import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/signed_url_cache.dart';
import '../data/entries_repository.dart';
import '../domain/elog_entry.dart';
import '../domain/logbook_sections.dart';

final logbookSectionProvider =
    StateProvider<String>((ref) => logbookSectionOpdCases);
final moduleSelectionProvider = StateProvider<String>((ref) => moduleCases);
final searchQueryProvider = StateProvider<String>((ref) => '');
final showMineProvider = StateProvider<bool>((ref) => true);
final showDraftsProvider = StateProvider<bool>((ref) => false);

final entriesListProvider = FutureProvider.autoDispose<List<ElogEntry>>((
  ref,
) async {
  final repo = ref.watch(entriesRepositoryProvider);
  final module = ref.watch(moduleSelectionProvider);
  final search = ref.watch(searchQueryProvider);
  final onlyMine = ref.watch(showMineProvider);
  final draftsOnly = ref.watch(showDraftsProvider);
  return repo
      .listEntries(
        moduleType: module,
        search: search.isEmpty ? null : search,
        onlyMine: draftsOnly ? true : onlyMine,
      )
      .then((list) {
        if (draftsOnly) {
          return list.where((e) => e.status == 'draft').toList();
        }
        return list;
      });
});

final entryDetailProvider = FutureProvider.family
    .autoDispose<ElogEntry, String>((ref, id) async {
      final repo = ref.watch(entriesRepositoryProvider);
      return repo.getEntry(id);
    });

class EntryMutationController extends StateNotifier<AsyncValue<void>> {
  EntryMutationController(this._entriesRepository)
    : super(const AsyncValue.data(null));

  final EntriesRepository _entriesRepository;

  Future<String> create(ElogEntryCreate data) async {
    state = const AsyncValue.loading();
    try {
      final entryId = await _entriesRepository.createEntry(data);
      state = const AsyncValue.data(null);
      return entryId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> update(String id, ElogEntryUpdate patch) async {
    state = const AsyncValue.loading();
    try {
      await _entriesRepository.updateEntry(id, patch);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    state = const AsyncValue.loading();
    try {
      await _entriesRepository.deleteEntry(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final entryMutationProvider =
    StateNotifierProvider<EntryMutationController, AsyncValue<void>>((ref) {
      final entriesRepo = ref.watch(entriesRepositoryProvider);
      return EntryMutationController(entriesRepo);
    });

/// Global signed URL cache with expiry
final signedUrlCacheProvider =
    StateNotifierProvider<SignedUrlCache, Map<String, SignedUrlEntry>>((ref) {
      return SignedUrlCache(ref.watch);
    });
