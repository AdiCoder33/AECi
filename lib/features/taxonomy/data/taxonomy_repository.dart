import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';

class KeywordTerm {
  KeywordTerm({required this.id, required this.term, required this.status});
  final String id;
  final String term;
  final String status;

  factory KeywordTerm.fromMap(Map<String, dynamic> map) => KeywordTerm(
        id: map['id'] as String,
        term: map['term'] as String,
        status: map['status'] as String,
      );
}

class KeywordSuggestion {
  KeywordSuggestion({
    required this.id,
    required this.suggestedTerm,
    required this.status,
    this.reviewedBy,
  });
  final String id;
  final String suggestedTerm;
  final String status;
  final String? reviewedBy;

  factory KeywordSuggestion.fromMap(Map<String, dynamic> map) => KeywordSuggestion(
        id: map['id'] as String,
        suggestedTerm: map['suggested_term'] as String,
        status: map['status'] as String,
        reviewedBy: map['reviewed_by'] as String?,
      );
}

class TaxonomyRepository {
  TaxonomyRepository(this._client);
  final SupabaseClient _client;

  Future<List<KeywordTerm>> autocomplete(String query) async {
    final rows = await _client
        .from('keyword_terms')
        .select('id, term, status')
        .ilike('term', '%$query%')
        .limit(10);
    return (rows as List)
        .map((e) => KeywordTerm.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> suggest(String term) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw AuthException('Not signed in');
    await _client.from('keyword_suggestions').insert({
      'suggested_term': term,
      'suggested_by': uid,
    });
  }

  Future<List<KeywordSuggestion>> listSuggestions() async {
    final rows = await _client
        .from('keyword_suggestions')
        .select('*')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => KeywordSuggestion.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> reviewSuggestion(String id, String decision) async {
    final uid = _client.auth.currentUser?.id;
    await _client.from('keyword_suggestions').update({
      'status': decision,
      'reviewed_by': uid,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
    if (decision == 'accepted') {
      final suggestion = await _client
          .from('keyword_suggestions')
          .select('suggested_term')
          .eq('id', id)
          .maybeSingle();
      if (suggestion != null) {
        await _client.from('keyword_terms').insert({
          'term': suggestion['suggested_term'],
          'normalized': suggestion['suggested_term'].toString().toLowerCase(),
          'created_by': uid,
        });
      }
    }
  }

  Future<void> mergeTerms(String fromId, String toId) async {
    final res = await _client.functions.invoke('taxonomy-merge', body: {
      'fromTermId': fromId,
      'toTermId': toId,
    });
    if (res.status >= 400) {
      throw res.data ?? 'Merge failed';
    }
  }
}

final taxonomyRepositoryProvider = Provider<TaxonomyRepository>((ref) {
  return TaxonomyRepository(ref.watch(supabaseClientProvider));
});
