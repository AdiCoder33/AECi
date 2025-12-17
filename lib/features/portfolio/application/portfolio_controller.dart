import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/portfolio_repository.dart';

class ResearchListNotifier extends StateNotifier<AsyncValue<List<ResearchProject>>> {
  ResearchListNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }
  final PortfolioRepository _repo;

  Future<void> load() async {
    try {
      final items = await _repo.listResearch();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class PublicationListNotifier
    extends StateNotifier<AsyncValue<List<PublicationItem>>> {
  PublicationListNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }
  final PortfolioRepository _repo;

  Future<void> load() async {
    try {
      final items = await _repo.listPublications();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class PortfolioMutationNotifier extends StateNotifier<AsyncValue<void>> {
  PortfolioMutationNotifier(this._repo) : super(const AsyncValue.data(null));
  final PortfolioRepository _repo;

  Future<String> createResearch(ResearchProject data) async {
    state = const AsyncValue.loading();
    try {
      final id = await _repo.createResearch(data);
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateResearch(String id, ResearchProject data) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateResearch(id, data);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<String> createPublication(PublicationItem data) async {
    state = const AsyncValue.loading();
    try {
      final id = await _repo.createPublication(data);
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updatePublication(String id, PublicationItem data) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updatePublication(id, data);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteResearch(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteResearch(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deletePublication(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deletePublication(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final researchListProvider = StateNotifierProvider<ResearchListNotifier,
    AsyncValue<List<ResearchProject>>>((ref) {
  final repo = ref.watch(portfolioRepositoryProvider);
  return ResearchListNotifier(repo);
});

final publicationListProvider = StateNotifierProvider<
    PublicationListNotifier, AsyncValue<List<PublicationItem>>>((ref) {
  final repo = ref.watch(portfolioRepositoryProvider);
  return PublicationListNotifier(repo);
});

final researchDetailProvider =
    FutureProvider.family<ResearchProject, String>((ref, id) {
  final repo = ref.watch(portfolioRepositoryProvider);
  return repo.getResearch(id);
});

final publicationDetailProvider =
    FutureProvider.family<PublicationItem, String>((ref, id) {
  final repo = ref.watch(portfolioRepositoryProvider);
  return repo.getPublication(id);
});

final portfolioMutationProvider =
    StateNotifierProvider<PortfolioMutationNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(portfolioRepositoryProvider);
  return PortfolioMutationNotifier(repo);
});
