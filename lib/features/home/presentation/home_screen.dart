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
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.go('/cases/notifications'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHeader(
                name: displayName,
                designation: profile?.designation,
                centre: profile?.aravindCentre ?? profile?.centre,
                onTap: () => context.go('/profile'),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search cases, logbook, teaching...',
                  ),
                  onSubmitted: (value) {
                    final query = value.trim();
                    if (query.isEmpty) return;
                    context.go('/search', extra: query);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logbook Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    fellowStats.when(
                      data: (stats) => _StatsGrid(
                        stats: [
                          _StatData('Drafts', stats.drafts, Icons.edit_note, const Color(0xFFF59E0B)),
                          _StatData('Submitted', stats.submitted, Icons.upload_file, const Color(0xFF0B5FFF)),
                          _StatData('Approved', stats.approved, Icons.check_circle_outline, const Color(0xFF10B981)),
                        ],
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Stats error: $e', style: const TextStyle(color: Colors.red)),
                    ),
                    if (isConsultant) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Consultant Dashboard',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      consultantStats.when(
                        data: (stats) => _StatsGrid(
                          stats: [
                            _StatData('Pending', stats.pending, Icons.pending_actions, const Color(0xFFF59E0B)),
                            _StatData('Approved', stats.approvalsThisMonth, Icons.verified_outlined, const Color(0xFF10B981)),
                          ],
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _ActionGrid(isConsultant: isConsultant),
                    const SizedBox(height: 24),
                  ],
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
      _ActionTile('Submit', Icons.send, '/submit', const Color(0xFF0B5FFF)),
      _ActionTile('Teaching', Icons.school, '/teaching', const Color(0xFFF59E0B)),
      _ActionTile('Analytics', Icons.insights, '/analytics', const Color(0xFF8B5CF6)),
      _ActionTile('Research', Icons.science, '/research', const Color(0xFFEC4899)),
      _ActionTile('Publications', Icons.slideshow, '/publications', const Color(0xFF06B6D4)),
      if (isConsultant) _ActionTile('Reviews', Icons.rate_review, '/review-queue', const Color(0xFFEF4444)),
      if (isConsultant)
        _ActionTile('Case Assessments', Icons.fact_check, '/cases/assessment-queue', const Color(0xFF0B5FFF)),
      if (isConsultant) _ActionTile('Proposals', Icons.inbox, '/teaching/proposals', const Color(0xFF6366F1)),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: tiles,
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(this.label, this.icon, this.route, this.color);

  final String label;
  final IconData icon;
  final String route;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5EAF2)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.designation,
    required this.centre,
    required this.onTap,
  });

  final String? name;
  final String? designation;
  final String? centre;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0B5FFF), Color(0xFF0A2E73)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B5FFF).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.visibility, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name ?? 'Aravind Trainee',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [designation, centre].where((e) => (e ?? '').isNotEmpty).join(' | '),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _StatData {
  const _StatData(this.label, this.value, this.icon, this.color);
  final String label;
  final int value;
  final IconData icon;
  final Color color;
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final List<_StatData> stats;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5EAF2)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: stat.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(stat.icon, color: stat.color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                '${stat.value}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                stat.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
              ),
            ],
          ),
        );
      },
    );
  }
}
