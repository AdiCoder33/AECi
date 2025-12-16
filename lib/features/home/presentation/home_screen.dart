import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final session = authState.session;

    return Scaffold(
      appBar: AppBar(title: const Text('Aravind E-Logbook')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Signed in', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            _InfoTile(
              label: 'Email',
              value: session?.user.email ?? 'Unavailable',
            ),
            const SizedBox(height: 8),
            _InfoTile(
              label: 'User ID',
              value: session?.user.id ?? 'Unavailable',
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: authState.isLoading
                  ? null
                  : () => ref.read(authControllerProvider.notifier).signOut(),
              icon: authState.isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.logout, color: Colors.black),
              label: Text(
                authState.isLoading ? 'Signing out...' : 'Logout',
                style: const TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
