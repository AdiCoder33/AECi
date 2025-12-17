import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';

class AssignmentsRepository {
  AssignmentsRepository(this._client);

  final SupabaseClient _client;

  Future<List<String>> traineeIdsForConsultant() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _client
        .from('supervisor_assignments')
        .select('trainee_id')
        .eq('consultant_id', uid);
    return (rows as List)
        .map((e) => (e as Map<String, dynamic>)['trainee_id'] as String)
        .toList();
  }
}

final assignmentsRepositoryProvider = Provider<AssignmentsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AssignmentsRepository(client);
});
