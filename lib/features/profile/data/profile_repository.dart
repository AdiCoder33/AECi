import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';
import 'profile_model.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<Profile?> getMyProfile() async {
    final userId = _userId;
    if (userId == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return Profile.fromMap(Map<String, dynamic>.from(response));
  }

  Future<Profile?> getProfileById(String id) async {
    final response =
        await _client.from('profiles').select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return Profile.fromMap(Map<String, dynamic>.from(response));
  }

  Future<void> upsertMyProfile(Profile profile) async {
    final userId = _userId;
    if (userId == null) {
      throw AuthException('User not signed in');
    }

    final data = profile.copyWith(id: userId).toMap();
    await _client.from('profiles').upsert(data, onConflict: 'id');
  }

  Stream<Profile?> watchMyProfile() {
    final userId = _userId;
    if (userId == null) {
      return const Stream.empty();
    }

    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) {
          if (rows.isEmpty) return null;
          return Profile.fromMap(Map<String, dynamic>.from(rows.first));
        });
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProfileRepository(client);
});
