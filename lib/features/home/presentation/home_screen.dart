import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../profile/application/profile_controller.dart';
import '../application/dashboard_providers.dart';
import '../../clinical_cases/application/notifications_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;
    final displayName = profile?.name;
    final isConsultant = profile?.designation == 'Consultant';
    final unreadCount = ref.watch(unreadCountProvider);

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
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
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
                // Submission / Assessments Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: isConsultant
                      ? const _AssessmentsCard()
                      : const _SubmissionCard(),
                ),
                const SizedBox(height: 24),
                // Daily Clinical Work Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Clinical Work',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _HorizontalCard(
                        title: 'OPD Cases',
                        description: 'View & manage OPD patients',
                        assetPath: 'assets/OpdCases.png',
                        color: const Color(0xFF0B5FFF),
                        route: '/logbook?section=opd_cases',
                      ),
                      const SizedBox(height: 12),
                      _HorizontalCard(
                        title: 'Surgical Records',
                        description: 'Log & review procedures',
                        assetPath: 'assets/SurgicalRecords.png',
                        color: const Color(0xFF0B5FFF),
                        route: '/logbook?section=surgical_record',
                      ),
                      const SizedBox(height: 12),
                      _HorizontalCard(
                        title: 'Retinoblastoma',
                        description: 'Screening & cases',
                        assetPath: 'assets/RBScreening.png',
                        color: const Color(0xFFEC4899),
                        route: '/logbook?section=retinoblastoma_screening',
                      ),
                      const SizedBox(height: 12),
                      _HorizontalCard(
                        title: 'ROP',
                        description: 'Screening & cases',
                        assetPath: 'assets/ROPScreening.png',
                        color: const Color(0xFF06B6D4),
                        route: '/logbook?section=rop_screening',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Knowledge & Tools Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Knowledge & Tools',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _SmallCard(
                              title: 'Learning',
                              description: 'Teaching resources',
                              assetPath: 'assets/Learning.png',
                              color: const Color(0xFFFEF3C7),
                              iconColor: const Color(0xFFF59E0B),
                              route: '/logbook?section=learning',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SmallCard(
                              title: 'Atlas',
                              description: 'Medical atlas',
                              assetPath: 'assets/Atlas.png',
                              color: const Color(0xFFDDD6FE),
                              iconColor: const Color(0xFF8B5CF6),
                              route: '/logbook?section=atlas',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Academic Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Academic',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _SmallCard(
                              title: 'Publications',
                              description: 'Research output',
                              assetPath: 'assets/Publications.png',
                              color: const Color(0xFFCFFAFE),
                              iconColor: const Color(0xFF14B8A6),
                              route: '/logbook?section=publications',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SmallCard(
                              title: 'Reviews',
                              description: 'Case validation',
                              assetPath: 'assets/Reviews.png',
                              color: const Color(0xFFE0E7FF),
                              iconColor: const Color(0xFF6366F1),
                              route: '/logbook?section=reviews',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
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
        color: const Color(0xFF14B8A6),
        route: '/publications',
        description: 'Research publications',
      ),
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
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.9,
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
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Image container
                Container(
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
                              print('❌ Failed to load: ${action.assetPath}');
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
                  textAlign: TextAlign.center,
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
                  textAlign: TextAlign.center,
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
              colors: [Color(0xFF0B5FFF), Color(0xFF0A47B8)],
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
          colors: [const Color(0xFF10B981), const Color(0xFF059669)],
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
            mainAxisSize: MainAxisSize.min,
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
                // Submit Button (always active for now)
                ElevatedButton(
                  onPressed: () => context.go('/submit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF10B981),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.send, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: const Text(
                          'Submit Now',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
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
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[month - 1];
  }
}

// ------------------------------
// Horizontal Card Component
// ------------------------------
class _HorizontalCard extends StatelessWidget {
  const _HorizontalCard({
    required this.title,
    required this.description,
    required this.assetPath,
    required this.color,
    required this.route,
  });

  final String title;
  final String description;
  final String assetPath;
  final Color color;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.image_outlined, color: color, size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------
// Small Card Component
// ------------------------------
class _SmallCard extends StatelessWidget {
  const _SmallCard({
    required this.title,
    required this.description,
    required this.assetPath,
    required this.color,
    required this.iconColor,
    required this.route,
  });

  final String title;
  final String description;
  final String assetPath;
  final Color color;
  final Color iconColor;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.image_outlined, color: iconColor, size: 24),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Description + Arrow
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Text(
                      description,
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------
// Assessments Card Component
// ------------------------------
class _AssessmentsCard extends ConsumerWidget {
  const _AssessmentsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(consultantDashboardProvider);

    final pendingText = statsAsync.when(
      data: (stats) => stats.pending == 0
          ? 'No pending submissions'
          : '${stats.pending} pending submissions',
      loading: () => 'Loading pending submissions...',
      error: (_, __) => 'Review submitted logbooks',
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.assignment_turned_in_outlined,
              color: Color(0xFF2563EB),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assessments',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pendingText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Button
          ElevatedButton(
            onPressed: () => context.go('/assessments'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2563EB),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Open',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
