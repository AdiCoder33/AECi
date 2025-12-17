import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';

class AnalyticsSnapshot {
  AnalyticsSnapshot({
    required this.id,
    required this.scope,
    required this.scopeId,
    required this.metrics,
    required this.periodStart,
    required this.periodEnd,
  });
  final String id;
  final String scope;
  final String scopeId;
  final Map<String, dynamic> metrics;
  final DateTime periodStart;
  final DateTime periodEnd;

  factory AnalyticsSnapshot.fromMap(Map<String, dynamic> map) => AnalyticsSnapshot(
        id: map['id'] as String,
        scope: map['scope'] as String,
        scopeId: map['scope_id'] as String,
        metrics: Map<String, dynamic>.from(map['metrics'] as Map),
        periodStart: DateTime.parse(map['period_start'] as String),
        periodEnd: DateTime.parse(map['period_end'] as String),
      );
}

class AnalyticsRepository {
  AnalyticsRepository(this._client);
  final SupabaseClient _client;

  Future<AnalyticsSnapshot> compute({
    required String scope,
    required String scopeId,
    int periodDays = 30,
  }) async {
    final res = await _client.functions.invoke('compute-analytics', body: {
      'scope': scope,
      'scopeId': scopeId,
      'periodDays': periodDays,
    });
    if (res.status >= 400) {
      throw res.data ?? 'Failed to compute analytics';
    }
    final metrics = Map<String, dynamic>.from(res.data['metrics'] as Map);
    final snapshot = await _client
        .from('analytics_snapshots')
        .select('*')
        .eq('scope', scope)
        .eq('scope_id', scopeId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (snapshot == null) {
      return AnalyticsSnapshot(
        id: 'temp',
        scope: scope,
        scopeId: scopeId,
        metrics: metrics,
        periodStart: DateTime.now(),
        periodEnd: DateTime.now(),
      );
    }
    return AnalyticsSnapshot.fromMap(Map<String, dynamic>.from(snapshot));
  }

  Future<List<AnalyticsSnapshot>> list(String scope, String scopeId) async {
    final rows = await _client
        .from('analytics_snapshots')
        .select('*')
        .eq('scope', scope)
        .eq('scope_id', scopeId)
        .order('created_at', ascending: false)
        .limit(10);
    return (rows as List)
        .map((e) => AnalyticsSnapshot.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.watch(supabaseClientProvider));
});
