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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0B5FFF),
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
        child: Container(
          color: const Color(0xFFF8FAFC),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Greeting Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _GreetingCard(
                    name: displayName,
                    designation: profile?.designation,
                    centre: profile?.centre,
                    onTap: () => context.go('/profile'),
                  ),
                ),
                const SizedBox(height: 24),
                // Quick Actions Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ActionGrid(isConsultant: isConsultant),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
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
    final actions = <_ActionData>[
      _ActionData(
        title: 'OPD Cases',
        assetPath: 'assets/OpdCases.png',
        color: const Color(0xFF10B981),
        route: '/cases',
        description: 'Manage outpatient cases',
      ),
      _ActionData(
        title: 'Atlas',
        assetPath: 'assets/Atlas.png',
        color: const Color(0xFF8B5CF6),
        route: '/atlas',
        description: 'Browse medical atlas',
      ),
      _ActionData(
        title: 'Surgical Record',
        assetPath: 'assets/SurgicalRecords.png',
        color: const Color(0xFFEF4444),
        route: '/surgical',
        description: 'Log surgical procedures',
      ),
      _ActionData(
        title: 'Learning',
        assetPath: 'assets/Learning.png',
        color: const Color(0xFFF59E0B),
        route: '/teaching',
        description: 'Educational resources',
      ),
      _ActionData(
        title: 'RB Screening',
        assetPath: 'assets/RBScreening.png',
        color: const Color(0xFFEC4899),
        route: '/screening/rb',
        description: 'Retinoblastoma screening',
      ),
      _ActionData(
        title: 'ROP Screening',
        assetPath: 'assets/ROPScreening.png',
        color: const Color(0xFF06B6D4),
        route: '/screening/rop',
        description: 'Retinopathy of prematurity',
      ),
      _ActionData(
        title: 'Publications',
        assetPath: 'assets/Publications.png',
        color: const Color(0xFF10B981),
        route: '/publications',
        description: 'Research publications',
      ),
      if (isConsultant)
        _ActionData(
          title: 'Reviews',
          assetPath: 'assets/Reviews.png',
          color: const Color(0xFF6366F1),
          route: '/review-queue',
          description: 'Review submissions',
        ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) => _ActionCard(action: actions[index]),
    );
  }
}

// Action data model
class _ActionData {
  const _ActionData({
    required this.title,
    this.assetPath,
    this.color = const Color(0xFF64748B),
    required this.route,
    required this.description,
  });

  final String title;
  final String? assetPath;
  final Color color;
  final String route;
  final String description;
}

// Modern Action Card with submit button
class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});

  final _ActionData action;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardHeight = screenWidth < 400 ? 150.0 : screenWidth * 0.42;
    return SizedBox(
      height: cardHeight,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: action.color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go(action.route),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: action.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: action.color.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: action.assetPath != null
                            ? Image.asset(
                                action.assetPath!,
                                width: 64,
                                height: 64,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  print(
                                    '❌ Failed to load: ${action.assetPath}',
                                  );
                                  print('Error: $error');
                                  return Icon(
                                    Icons.broken_image_outlined,
                                    color: action.color,
                                    size: 32,
                                  );
                                },
                              )
                            : Icon(
                                Icons.image_outlined,
                                color: action.color,
                                size: 32,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Text(
                      action.description,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 24,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: action.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Open',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: action.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Greeting Card Component
class _GreetingCard extends StatelessWidget {
  const _GreetingCard({
    required this.name,
    required this.designation,
    required this.centre,
    required this.onTap,
  });

  final String? name;
  final String? designation;
  final String? centre;
  final VoidCallback onTap;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B5FFF), Color(0xFF0A47B8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B5FFF).withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.visibility,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name ?? 'Aravind Trainee',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (designation != null || centre != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          [
                            designation,
                            centre,
                          ].where((e) => (e ?? '').isNotEmpty).join(' • '),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              // Arrow icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
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
