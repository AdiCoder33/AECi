import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';

class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.entityType,
    required this.entityId,
    required this.isRead,
    required this.createdAt,
  });
  final String id;
  final String type;
  final String title;
  final String body;
  final String entityType;
  final String entityId;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
        id: map['id'] as String,
        type: map['type'] as String,
        title: map['title'] as String,
        body: map['body'] as String,
        entityType: map['entity_type'] as String,
        entityId: map['entity_id'] as String,
        isRead: map['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class NotificationsRepository {
  NotificationsRepository(this._client);
  final SupabaseClient _client;

  Stream<List<AppNotification>> subscribe() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return const Stream.empty();
    }
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map((e) => AppNotification.fromMap(Map<String, dynamic>.from(e)))
              .toList(),
        );
  }

  Future<void> markRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }
}

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(supabaseClientProvider));
});
