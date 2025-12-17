import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/entries_repository.dart';
import '../data/media_repository.dart';
import '../domain/elog_entry.dart';

final moduleSelectionProvider = StateProvider<String>((ref) => moduleCases);
final searchQueryProvider = StateProvider<String>((ref) => '');

final entriesListProvider = FutureProvider.autoDispose<List<ElogEntry>>((
  ref,
) async {
  final repo = ref.watch(entriesRepositoryProvider);
  final module = ref.watch(moduleSelectionProvider);
  final search = ref.watch(searchQueryProvider);
  return repo.listEntries(
    moduleType: module,
    search: search.isEmpty ? null : search,
  );
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

class SignedUrlCache extends StateNotifier<Map<String, String>> {
  SignedUrlCache(this._mediaRepository) : super({});

  final MediaRepository _mediaRepository;

  Future<String> getUrl(String path) async {
    if (state.containsKey(path)) return state[path]!;
    final url = await _mediaRepository.getSignedUrl(path);
    state = {...state, path: url};
    return url;
  }
}

final signedUrlCacheProvider =
    StateNotifierProvider<SignedUrlCache, Map<String, String>>((ref) {
      final mediaRepo = ref.watch(mediaRepositoryProvider);
      return SignedUrlCache(mediaRepo);
    });
