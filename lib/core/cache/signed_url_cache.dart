import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/logbook/data/media_repository.dart';

class SignedUrlEntry {
  SignedUrlEntry({required this.url, required this.expiresAt});

  final String url;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class SignedUrlCache extends StateNotifier<Map<String, SignedUrlEntry>> {
  SignedUrlCache(this._watch) : super({});

  final T Function<T>(ProviderListenable<T> provider) _watch;

  Future<String> getUrl(String path) async {
    final existing = state[path];
    if (existing != null && !existing.isExpired) {
      return existing.url;
    }
    final mediaRepo = _watch(mediaRepositoryProvider);
    final url = await mediaRepo.getSignedUrl(path);
    final entry = SignedUrlEntry(
      url: url,
      expiresAt: DateTime.now().add(const Duration(minutes: 45)),
    );
    state = {...state, path: entry};
    return url;
  }
}

final signedUrlCacheProvider =
    StateNotifierProvider<SignedUrlCache, Map<String, SignedUrlEntry>>((ref) {
      return SignedUrlCache(ref.watch);
    });
