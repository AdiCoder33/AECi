import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../profile/application/profile_controller.dart';
import '../application/dashboard_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;
    final displayName = profile?.name;
    final isConsultant = profile?.designation == 'Consultant';
    final fellowStats = ref.watch(fellowDashboardProvider);
    final consultantStats = ref.watch(consultantDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aravind E-Logbook'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/search'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome${displayName != null ? ', $displayName' : ''}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _InfoTile(
              label: 'Designation',
              value: profile?.designation ?? 'Pending',
            ),
            const SizedBox(height: 8),
            _InfoTile(label: 'Centre', value: profile?.centre ?? 'Pending'),
            const SizedBox(height: 8),
            _InfoTile(
              label: 'Email',
              value: profile?.email ?? authState.session?.user.email ?? '',
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Logbook snapshot',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            fellowStats.when(
              data: (stats) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatPill(label: 'Drafts', value: stats.drafts),
                  _StatPill(label: 'Submitted', value: stats.submitted),
                  _StatPill(label: 'Approved', value: stats.approved),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Stats error: $e'),
            ),
            if (isConsultant) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Consultant dashboard',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 6),
              consultantStats.when(
                data: (stats) => Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatPill(label: 'Pending review', value: stats.pending),
                    _StatPill(
                      label: 'Approvals this month',
                      value: stats.approvalsThisMonth,
                    ),
                  ],
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Consultant stats error: $e'),
              ),
            ],
            const Spacer(),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/logbook'),
                        icon: const Icon(Icons.book, color: Colors.black),
                        label: const Text(
                          'Open Logbook',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/profile'),
                        icon: const Icon(Icons.person, color: Colors.black),
                        label: const Text(
                          'Profile',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/teaching'),
                        icon: const Icon(Icons.school, color: Colors.black),
                        label: const Text(
                          'Teaching Library',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/analytics'),
                        icon: const Icon(Icons.insights, color: Colors.black),
                        label: const Text(
                          'Analytics',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/research'),
                        icon: const Icon(Icons.science, color: Colors.black),
                        label: const Text(
                          'Research',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/publications'),
                        icon: const Icon(Icons.slideshow, color: Colors.black),
                        label: const Text(
                          'Presentations',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isConsultant)
                  ElevatedButton.icon(
                    onPressed: () => context.go('/review-queue'),
                    icon: const Icon(Icons.rate_review, color: Colors.black),
                    label: const Text(
                      'Review queue',
                      style: TextStyle(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                if (isConsultant) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/teaching/proposals'),
                    icon: const Icon(Icons.inbox, color: Colors.black),
                    label: const Text(
                      'Teaching proposals',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/taxonomy/suggestions'),
                    icon: const Icon(Icons.list_alt, color: Colors.black),
                    label: const Text(
                      'Keyword suggestions',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
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

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
