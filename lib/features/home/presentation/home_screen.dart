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
        title: const Text('Reti-Notes'),
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
          child:  Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _ProfileCard(
                  name: displayName,
                  designation: profile?.designation,
                  centre: profile?.aravindCentre ??  profile?.centre,
                  onTap: () => context.go('/profile'),
                ),
                const SizedBox(height: 20),
                Text(
                  'Quick Access',
                  style: Theme.of(context).textTheme.titleLarge?. copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E5F8C),
                      ),
                ),
                const SizedBox(height:  16),
                _ActionGrid(isConsultant: isConsultant),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this. isConsultant});

  final bool isConsultant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final tiles = <_ActionTile>[
      const _ActionTile('OPD Cases', Icons.medical_services_outlined, '/logbook', Color(0xFF0B5FFF)),
      const _ActionTile('Atlas', Icons.photo_library_outlined, '/atlas', Color(0xFF10B981)),
      const _ActionTile('Analysis Record', Icons.analytics_outlined, '/analytics', Color(0xFF8B5CF6)),
      const _ActionTile('Learning', Icons.school_outlined, '/teaching', Color(0xFFF59E0B)),
      const _ActionTile('Retinoblastoma', Icons.remove_red_eye_outlined, '/retinoblastoma', Color(0xFFEC4899)),
      const _ActionTile('ROP', Icons.child_care_outlined, '/rop', Color(0xFF06B6D4)),
      const _ActionTile('Publication', Icons.article_outlined, '/publications', Color(0xFF6366F1)),
      if (isConsultant) const _ActionTile('Reviews', Icons.rate_review_outlined, '/review-queue', Color(0xFFEF4444)),
      if (isConsultant) const _ActionTile('Case Assessments', Icons.fact_check, '/cases/assessment-queue', Color(0xFF0B5FFF)),
      if (isConsultant) const _ActionTile('Proposals', Icons.inbox, '/teaching/proposals', Color(0xFF14B8A6)),
    ];

    return GridView.count(
      shrinkWrap:  true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing:  16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius:  8,
                    offset:  const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isDark ?  Colors.white : const Color(0xFF1E293B),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
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
    // Get greeting based on time of day
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
    Color iconColor;
    if (hour < 12) {
      greeting = 'Good Morning';
      greetingIcon = Icons.wb_sunny;
      iconColor = Colors.amber;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_sunny_outlined;
      iconColor = Colors.orange;
    } else if (hour < 21) {
      greeting = 'Good Evening';
      greetingIcon = Icons.nightlight_round;
      iconColor = const Color(0xFF6366F1);
    } else {
      greeting = 'Good Night';
      greetingIcon = Icons.bedtime;
      iconColor = const Color(0xFF8B5CF6);
    }
    
    // Get role-specific greeting
    String roleGreeting = '';
    if (designation != null) {
      switch (designation!. toLowerCase()) {
        case 'fellow':
          roleGreeting = 'Fellow';
          break;
        case 'consultant':
          roleGreeting = 'Consultant';
          break;
        case 'reviewer':
          roleGreeting = 'Reviewer';
          break;
        case 'resident':
          roleGreeting = 'Resident';
          break;
        default:
          roleGreeting = 'Professional';
      }
    }
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin:  Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:  BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:  const Color(0xFF667EEA).withOpacity(0.35),
              blurRadius:  16,
              offset: const Offset(0, 6),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.25),
                border: Border.all(
                  color: Colors. white.withOpacity(0.5),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius:  10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.visibility_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width:  16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        greetingIcon,
                        color: iconColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        greeting,
                        style:  TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name ?? 'Aravind Trainee',
                    style: const TextStyle(
                      color:  Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (roleGreeting. isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border. all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child:  Row(
                            mainAxisSize:  MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.workspace_premium_rounded,
                                size: 11,
                                color: Colors. amber[300],
                              ),
                              const SizedBox(width: 3),
                              Text(
                                roleGreeting,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (centre != null && centre!.isNotEmpty)
                        Flexible(
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 11,
                                color: Colors.white.withOpacity(0.85),
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  centre!,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow. ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
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
  const _StatsGrid({required this. stats});
  final List<_StatData> stats;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap:  true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing:  10,
        childAspectRatio: 0.95,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius. circular(14),
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
                  color: stat. color. withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:  Icon(stat.icon, color: stat.color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                '${stat.value}',
                style: const TextStyle(
                  fontSize:  20,
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