import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_controller.dart';

enum _ReviewerMenu { profile, logout }

class ReviewerAppBarActions extends ConsumerWidget {
  const ReviewerAppBarActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_ReviewerMenu>(
      onSelected: (value) async {
        switch (value) {
          case _ReviewerMenu.profile:
            context.go('/profile');
            break;
          case _ReviewerMenu.logout:
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await ref.read(authControllerProvider.notifier).signOut();
            }
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _ReviewerMenu.profile,
          child: Text('Profile'),
        ),
        PopupMenuItem(
          value: _ReviewerMenu.logout,
          child: Text('Logout'),
        ),
      ],
    );
  }
}
