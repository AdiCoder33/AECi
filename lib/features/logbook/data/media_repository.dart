import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';

const _bucket = 'elogbook-media';

class MediaRepository {
  MediaRepository(this._client);

  final SupabaseClient _client;

  Future<String> uploadImage({
    required String entryId,
    required File file,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw AuthException('Not signed in');
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final path = '$userId/$entryId/$fileName';
    await _client.storage.from(_bucket).upload(path, file);
    return path;
  }

  Future<String> getSignedUrl(String path) async {
    final response = await _client.storage
        .from(_bucket)
        .createSignedUrl(path, 60 * 60); // 60 minutes
    return response;
  }
}

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return MediaRepository(client);
});
