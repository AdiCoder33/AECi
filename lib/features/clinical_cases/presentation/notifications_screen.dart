import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/notifications_controller.dart';
import '../data/notifications_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(notificationsStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: stream.when(
        data: (list) => ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final n = list[i];
            return ListTile(
              title: Text(n.title),
              subtitle: Text(n.body),
              trailing: n.isRead ? null : const Icon(Icons.brightness_1, size: 8),
              onTap: () async {
                await ref
                    .read(notificationsRepositoryProvider)
                    .markRead(n.id);
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
