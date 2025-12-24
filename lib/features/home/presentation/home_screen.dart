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
      body: SafeArea(
        child: SingleChildScrollView(
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
              const SizedBox(height: 20),
              _ActionGrid(isConsultant: isConsultant),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: authState.isLoading
                    ? null
                    : () => ref.read(authControllerProvider.notifier).signOut(),
                icon: authState.isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout),
                label: Text(authState.isLoading ? 'Signing out...' : 'Logout'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.isConsultant});

  final bool isConsultant;

  @override
  Widget build(BuildContext context) {
    final tiles = <_ActionTile>[
      _ActionTile('Open Logbook', Icons.book, '/logbook'),
      _ActionTile('Profile', Icons.person, '/profile'),
      _ActionTile('Teaching Library', Icons.school, '/teaching'),
      _ActionTile('Analytics', Icons.insights, '/analytics'),
      _ActionTile('Research', Icons.science, '/research'),
      _ActionTile('Presentations', Icons.slideshow, '/publications'),
      if (isConsultant) _ActionTile('Review queue', Icons.rate_review, '/review-queue'),
      if (isConsultant) _ActionTile('Teaching proposals', Icons.inbox, '/teaching/proposals'),
      if (isConsultant) _ActionTile('Keyword suggestions', Icons.list_alt, '/taxonomy/suggestions'),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: tiles,
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: OutlinedButton.icon(
        onPressed: () => context.go(route),
        icon: Icon(icon),
        label: Text(label, textAlign: TextAlign.start),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1,
                  color: Colors.blueGrey,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
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
