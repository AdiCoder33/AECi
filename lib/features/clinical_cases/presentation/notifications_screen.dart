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
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Notifications'),
        iconTheme: const IconThemeData(color: Color(0xFF0B5FFF)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF0B5FFF),
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      body: stream.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You are all caught up!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final n = list[i];
              return Material(
                color: n.isRead ? Colors.white : const Color(0xFF0B5FFF).withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    await ref.read(notificationsRepositoryProvider).markRead(n.id);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          n.isRead ? Icons.notifications_none : Icons.notifications_active,
                          color: n.isRead ? const Color(0xFF64748B) : const Color(0xFF0B5FFF),
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                style: TextStyle(
                                  fontWeight: n.isRead ? FontWeight.w500 : FontWeight.bold,
                                  fontSize: 15,
                                  color: n.isRead ? const Color(0xFF64748B) : const Color(0xFF0B172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.body,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            margin: const EdgeInsets.only(left: 8, top: 2),
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0B5FFF),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0B5FFF))),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load notifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
