import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';
import '../../logbook/domain/elog_entry.dart';

class ReviewsRepository {
  ReviewsRepository(this._client);

  final SupabaseClient _client;

  Future<void> submitReview({
    required String entryId,
    required String decision,
    required String comment,
    required List<String> requiredChanges,
  }) async {
    final reviewerId = _client.auth.currentUser?.id;
    if (reviewerId == null) throw AuthException('Not signed in');

    final now = DateTime.now().toIso8601String();
    await _client.from('elog_entries').update({
      'status': decision == 'approved'
          ? statusApproved
          : decision == 'rejected'
              ? statusRejected
              : statusNeedsRevision,
      'reviewed_at': now,
      'reviewed_by': reviewerId,
      'review_comment': comment,
      'required_changes': requiredChanges,
    }).eq('id', entryId);

    await _client.from('elog_entry_reviews').insert({
      'entry_id': entryId,
      'reviewer_id': reviewerId,
      'decision': decision,
      'comment': comment,
      'required_changes': requiredChanges,
    });
  }
}

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ReviewsRepository(client);
});
