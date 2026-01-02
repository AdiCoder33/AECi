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
        title: const Text('RetiNotes'),
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
                    centre: profile?.aravindCentre ?? profile?.centre,
                    photoUrl: profile?.profilePhotoUrl,
                    onTap: () => context.go('/profile'),
                  ),
                ),
                const SizedBox(height: 20),
                // Submission Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SubmissionCard(),
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
        icon: Icons.local_hospital,
        color: const Color(0xFF10B981),
        route: '/cases',
        description: 'Manage outpatient cases',
      ),
      _ActionData(
        title: 'Atlas',
        icon: Icons.collections,
        color: const Color(0xFF8B5CF6),
        route: '/atlas',
        description: 'Browse medical atlas',
      ),
      _ActionData(
        title: 'Surgical Record',
        icon: Icons.medical_services,
        color: const Color(0xFFEF4444),
        route: '/surgical',
        description: 'Log surgical procedures',
      ),
      _ActionData(
        title: 'Learning',
        icon: Icons.school,
        color: const Color(0xFFF59E0B),
        route: '/teaching',
        description: 'Educational resources',
      ),
      _ActionData(
        title: 'RB Screening',
        icon: Icons.child_care,
        color: const Color(0xFFEC4899),
        route: '/screening/rb',
        description: 'Retinoblastoma screening',
      ),
      _ActionData(
        title: 'ROP Screening',
        icon: Icons.baby_changing_station,
        color: const Color(0xFF06B6D4),
        route: '/screening/rop',
        description: 'Retinopathy of prematurity',
      ),
      _ActionData(
        title: 'Publications',
        icon: Icons.article,
        color: const Color(0xFF14B8A6),
        route: '/publications',
        description: 'Research publications',
      ),
      _ActionData(
        title: 'Reviews',
        icon: Icons.rate_review,
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
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.15,
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
    required this.icon,
    required this.color,
    required this.route,
    required this.description,
  });

  final String title;
  final IconData icon;
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: action.color.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(action.route),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon container
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        action.color,
                        action.color.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: action.color.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    action.icon,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                // Title
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
                const SizedBox(height: 4),
                // Description
                Text(
                  action.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
    required this.photoUrl,
    required this.onTap,
  });

  final String? name;
  final String? designation;
  final String? centre;
  final String? photoUrl;
  final VoidCallback onTap;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getCaption() {
    final captions = [
      'Vision is the art of seeing what is invisible to others',
      'The eye is the window to the soul',
      'Excellence in ophthalmology, compassion in care',
      'Restoring vision, transforming lives',
      'Every eye tells a story, every patient matters',
    ];
    return captions[DateTime.now().day % captions.length];
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0B5FFF),
                Color(0xFF0A47B8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B5FFF).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Profile Photo
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2.5,
                  ),
                  image: photoUrl != null && photoUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: photoUrl == null || photoUrl!.isEmpty
                    ? Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.visibility,
                          color: Colors.white,
                          size: 34,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Content: Greeting + Name inline, Designation, Caption
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Greeting and Name on same line
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${_getGreeting()}, ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: name ?? 'Aravind Trainee',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Designation
                    if (designation != null)
                      Text(
                        designation!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    // Caption
                    Text(
                      _getCaption(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.8),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Submission Card Component
class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Static submission date - set to 10th of current month for demo
    final submissionDate = DateTime(now.year, now.month, 10);
    final daysToGo = submissionDate.difference(now).inDays;
    final isSubmissionDay = daysToGo <= 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981),
            const Color(0xFF059669),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Calendar Display - Three boxes in a row
          Row(
            children: [
              // Day Box
              Container(
                width: 48,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    now.day.toString(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Month Box
              Container(
                width: 48,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getMonthAbbr(now.month),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Year Box
              Container(
                width: 48,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    now.year.toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Submission Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSubmissionDay
                      ? 'Submit Today!'
                      : '$daysToGo day${daysToGo == 1 ? '' : 's'} to go',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                // Submit Button
                ElevatedButton(
                  onPressed: isSubmissionDay ? () => context.go('/submit') : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF10B981),
                    disabledBackgroundColor: Colors.white.withOpacity(0.3),
                    disabledForegroundColor: Colors.white.withOpacity(0.6),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSubmissionDay ? Icons.send : Icons.lock_outline,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isSubmissionDay ? 'Submit Now' : 'Locked',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }
}
