import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';
import '../../profile/data/profile_model.dart';

class CommunityRepository {
  CommunityRepository(this._client);

  final SupabaseClient _client;

  Future<List<Profile>> listProfiles() async {
    final uid = _client.auth.currentUser?.id;
    var query = _client.from('profiles').select('*');
    if (uid != null) {
      query = query.filter('id', 'neq', uid);
    }
    final rows = await query.order('designation').order('name');
    return (rows as List)
        .map((row) => Profile.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Profile?> getProfile(String id) async {
    final row =
        await _client.from('profiles').select('*').eq('id', id).maybeSingle();
    if (row == null) return null;
    return Profile.fromMap(Map<String, dynamic>.from(row));
  }
}

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(ref.watch(supabaseClientProvider));
});
