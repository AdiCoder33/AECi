import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notifications_repository.dart';

final notificationsStreamProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
  return ref.watch(notificationsRepositoryProvider).subscribe();
});

final unreadCountProvider = Provider.autoDispose<int>((ref) {
  final stream = ref.watch(notificationsStreamProvider).valueOrNull;
  if (stream == null) return 0;
  return stream.where((n) => !n.isRead).length;
});
