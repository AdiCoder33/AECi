import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/loading_screen.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/profile/application/profile_controller.dart';
import '../features/profile/presentation/create_profile_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/profile_media_screen.dart';
import '../features/logbook/presentation/logbook_screen.dart';
import '../features/logbook/presentation/entry_detail_screen.dart';
import '../features/logbook/presentation/entry_form_screen.dart';
import '../features/search/presentation/global_search_screen.dart';
import '../features/export/presentation/export_screen.dart';
import '../features/profile/tools/storage_management_screen.dart';
import '../features/review/presentation/review_queue_screen.dart';
import '../features/review/presentation/review_detail_screen.dart';
import '../features/portfolio/presentation/research_screens.dart';
import '../features/portfolio/presentation/publication_screens.dart';
import '../features/teaching/presentation/teaching_list_screen.dart';
import '../features/analytics/presentation/analytics_screen.dart';
import '../features/teaching/data/teaching_repository.dart';
import '../features/teaching/proposal_screens.dart';
import '../features/taxonomy/presentation/keyword_suggestions_screen.dart';
import '../features/clinical_cases/presentation/case_list_screen.dart';
import '../features/clinical_cases/presentation/case_detail_screen.dart';
import '../features/clinical_cases/presentation/notifications_screen.dart';
import '../features/clinical_cases/presentation/assessment_queue_screen.dart';
import '../features/clinical_cases/presentation/case_followup_form_screen.dart';
import '../features/clinical_cases/presentation/case_media_screen.dart';
import '../features/clinical_cases/presentation/wizard/clinical_case_wizard_screen.dart';
import '../features/clinical_cases/presentation/retinoblastoma_form_screen.dart';
import '../features/clinical_cases/presentation/rop_screening_form_screen.dart';
import '../features/clinical_cases/presentation/laser_form_screen.dart';
import '../features/reviewer/presentation/reviewer_queue_screen.dart';
import '../features/reviewer/presentation/reviewer_reviewed_screen.dart';
import '../features/reviewer/presentation/reviewer_assessment_screen.dart';
import '../features/reviewer/data/reviewer_repository.dart';
import '../features/community/presentation/community_screen.dart';
import '../features/community/presentation/community_profile_screen.dart';
import '../features/submissions/presentation/logbook_submission_screen.dart';
import '../splash/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final authChanges = ref.watch(authStateChangesProvider);
  final profileStream = ref.watch(profileChangesProvider);
  final profileState = ref.watch(profileControllerProvider);

  final refreshStream = StreamGroup.merge([authChanges, profileStream]);

  return GoRouter(
    initialLocation: '/loading',
    refreshListenable: GoRouterRefreshStream(refreshStream),
    redirect: (context, state) {
      final loggedIn = authState.session != null;
      final onAuthRoute = state.matchedLocation == '/auth';
      final onCreateProfile = state.matchedLocation == '/profile/create';
      final onProfileView = state.matchedLocation == '/profile';
      final hasProfile = profileState.profile != null;
      final isReviewer = profileState.profile?.designation == 'Reviewer';
      final onLoadingRoute = state.matchedLocation == '/loading';

      if (!authState.initialized || (loggedIn && !profileState.initialized)) {
        if (!onLoadingRoute) return '/loading';
        return null;
      }

      if (!loggedIn && !onAuthRoute) {
        return '/auth';
      }

      if (loggedIn && onAuthRoute) {
        if (!hasProfile) return '/profile/create';
        return '/home';
      }

      if (loggedIn && !hasProfile && !onCreateProfile) {
        return '/profile/create';
      }

      if (loggedIn && hasProfile && onCreateProfile) {
        return '/home';
      }

      if (loggedIn && hasProfile && isReviewer) {
        final onReviewerRoute = state.matchedLocation.startsWith('/reviewer');
        final onProfileRoute = state.matchedLocation.startsWith('/profile');
        if (!onReviewerRoute && !onProfileRoute) {
          return '/reviewer/pending';
        }
      }

      return null;
    },
    routes: [
      // Splash screen removed for direct GIF launch
      GoRoute(
        path: '/loading',
        name: 'loading',
        builder: (context, state) => const LoadingScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/profile/create',
        name: 'createProfile',
        builder: (context, state) => const CreateProfileScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final profile = ref.watch(profileControllerProvider).profile;
          final authNotifier = ref.read(authControllerProvider.notifier);
          return _MainShell(
            location: state.matchedLocation,
            child: child,
            name: profile?.name,
            designation: profile?.designation,
            centre: profile?.aravindCentre ?? profile?.centre,
            isReviewer: profile?.designation == 'Reviewer',
            onSignOut: authNotifier.signOut,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/logbook',
            name: 'logbook',
            builder: (context, state) {
              final section = state.uri.queryParameters['section'];
              return LogbookScreen(
                key: ValueKey(section ?? 'default'),
                initialSection: section,
              );
            },
            routes: [
              GoRoute(
                path: 'new',
                name: 'logbookNew',
                builder: (context, state) {
                  final module = state.extra as String?;
                  return EntryFormScreen(moduleType: module);
                },
              ),
              GoRoute(
                path: ':id',
                name: 'logbookDetail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return EntryDetailScreen(entryId: id);
                },
              ),
              GoRoute(
                path: ':id/edit',
                name: 'logbookEdit',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  final module = state.extra as String?;
                  return EntryFormScreen(entryId: id, moduleType: module);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/community',
            name: 'community',
            builder: (context, state) => const CommunityScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'communityProfile',
                builder: (context, state) => CommunityProfileScreen(
                  profileId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/profile/edit',
            name: 'editProfile',
            builder: (context, state) {
              final profile = ref.watch(profileControllerProvider).profile;
              return CreateProfileScreen(profile: profile);
            },
          ),
          GoRoute(
            path: '/profile/media',
            name: 'profileMedia',
            builder: (context, state) => const ProfileMediaScreen(),
          ),
          GoRoute(
            path: '/research',
            name: 'researchList',
            builder: (context, state) => const ResearchListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'researchNew',
                builder: (context, state) => const ResearchFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'researchDetail',
                builder: (context, state) =>
                    ResearchDetailScreen(id: state.pathParameters['id']!),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'researchEdit',
                builder: (context, state) =>
                    ResearchFormScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/publications',
            name: 'pubList',
            builder: (context, state) => const PublicationListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'pubNew',
                builder: (context, state) => const PublicationFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'pubDetail',
                builder: (context, state) =>
                    PublicationDetailScreen(id: state.pathParameters['id']!),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'pubEdit',
                builder: (context, state) =>
                    PublicationFormScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (context, state) =>
                GlobalSearchScreen(initialQuery: state.extra as String?),
          ),
          GoRoute(
            path: '/review-queue',
            name: 'reviewQueue',
            builder: (context, state) => const ReviewQueueScreen(),
          ),
          GoRoute(
            path: '/review/:id',
            name: 'reviewDetail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ReviewDetailScreen(entryId: id);
            },
          ),
          GoRoute(
            path: '/export',
            name: 'export',
            builder: (context, state) => const ExportScreen(),
          ),
          GoRoute(
            path: '/storage-tools',
            name: 'storageTools',
            builder: (context, state) => const StorageManagementScreen(),
          ),
          GoRoute(
            path: '/teaching',
            name: 'teaching',
            builder: (context, state) => const TeachingListScreen(),
            routes: [
              GoRoute(
                path: 'proposals',
                name: 'teachingProposals',
                builder: (context, state) => const TeachingProposalsScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'teachingDetail',
                builder: (context, state) {
                  final item = state.extra as TeachingItem;
                  return TeachingDetailScreen(item: item);
                },
              ),
              GoRoute(
                path: 'proposal/:proposalId/:id',
                name: 'proposalReview',
                builder: (context, state) => ProposalReviewScreen(
                  proposalId: state.pathParameters['proposalId']!,
                  entryId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/submit',
            name: 'submit',
            builder: (context, state) => const LogbookSubmissionScreen(),
          ),
          GoRoute(
            path: '/taxonomy/suggestions',
            name: 'taxonomySuggestions',
            builder: (context, state) => const KeywordSuggestionsScreen(),
          ),
          GoRoute(
            path: '/cases',
            name: 'cases',
            builder: (context, state) => const ClinicalCaseListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'caseNew',
                builder: (context, state) {
                  final type = state.uri.queryParameters['type'];
                  if (type == 'retinoblastoma') {
                    return const RetinoblastomaScreeningFormScreen();
                  }
                  if (type == 'rop') {
                    return const RopScreeningFormScreen();
                  }
                  if (type == 'laser') {
                    return const LaserFormScreen();
                  }
                  return ClinicalCaseWizardScreen(caseType: type);
                },
              ),
              GoRoute(
                path: ':id',
                name: 'caseDetail',
                builder: (context, state) => ClinicalCaseDetailScreen(
                  caseId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'caseEdit',
                builder: (context, state) {
                  final type = state.uri.queryParameters['type'];
                  if (type == 'retinoblastoma') {
                    return RetinoblastomaScreeningFormScreen(
                      caseId: state.pathParameters['id']!,
                    );
                  }
                  if (type == 'rop') {
                    return RopScreeningFormScreen(
                      caseId: state.pathParameters['id']!,
                    );
                  }
                  if (type == 'laser') {
                    return LaserFormScreen(caseId: state.pathParameters['id']!);
                  }
                  return ClinicalCaseWizardScreen(
                    caseId: state.pathParameters['id']!,
                    caseType: type,
                  );
                },
              ),
              GoRoute(
                path: 'notifications',
                name: 'notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
              GoRoute(
                path: 'assessment-queue',
                name: 'assessmentQueue',
                builder: (context, state) => const AssessmentQueueScreen(),
              ),
              GoRoute(
                path: ':id/followup',
                name: 'caseFollowupNew',
                builder: (context, state) =>
                    CaseFollowupFormScreen(caseId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: ':id/followup/:followupId',
                name: 'caseFollowupEdit',
                builder: (context, state) => CaseFollowupFormScreen(
                  caseId: state.pathParameters['id']!,
                  followupId: state.pathParameters['followupId']!,
                ),
              ),
              GoRoute(
                path: ':id/media',
                name: 'caseMedia',
                builder: (context, state) =>
                    CaseMediaScreen(caseId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/reviewer/pending',
            name: 'reviewerPending',
            builder: (context, state) => const ReviewerQueueScreen(),
            routes: [
              GoRoute(
                path: 'assess/:type/:id',
                name: 'reviewerAssess',
                builder: (context, state) {
                  final item = state.extra as ReviewItem;
                  return ReviewerAssessmentScreen(item: item);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/reviewer/reviewed',
            name: 'reviewerReviewed',
            builder: (context, state) => const ReviewerReviewedScreen(),
          ),
        ],
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _MainShell extends StatelessWidget {
  const _MainShell({
    required this.child,
    required this.location,
    this.name,
    this.designation,
    this.centre,
    this.isReviewer = false,
    this.onSignOut,
  });

  final Widget child;
  final String location;
  final String? name;
  final String? designation;
  final String? centre;
  final bool isReviewer;
  final Future<void> Function()? onSignOut;

  int get _index {
    if (isReviewer) {
      if (location.startsWith('/reviewer/reviewed')) return 1;
      return 0;
    }
    if (location.startsWith('/logbook') ||
        location.startsWith('/cases') ||
        location.startsWith('/publications') ||
        location.startsWith('/review')) {
      return 1;
    }
    if (location.startsWith('/community')) return 2;
    if (location.startsWith('/analytics')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int i) {
    if (isReviewer) {
      switch (i) {
        case 0:
          context.go('/reviewer/pending');
          break;
        case 1:
          context.go('/reviewer/reviewed');
          break;
      }
      return;
    }
    switch (i) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/logbook');
        break;
      case 2:
        context.go('/community');
        break;
      case 3:
        context.go('/analytics');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  PreferredSizeWidget? get appBar => null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _AppDrawer(
        current: location,
        name: name,
        designation: designation,
        centre: centre,
        onNavigate: (route) => context.go(route),
        onSignOut: onSignOut,
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => _onTap(context, i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0B5FFF),
        unselectedItemColor: const Color(0xFF64748B),
        selectedFontSize: 12,
        unselectedFontSize: 11,
        elevation: 8,
        items: isReviewer
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.assignment_outlined),
                  activeIcon: Icon(Icons.assignment),
                  label: 'To Assess',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.check_circle_outline),
                  activeIcon: Icon(Icons.check_circle),
                  label: 'Reviewed',
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book_outlined),
                  activeIcon: Icon(Icons.menu_book),
                  label: 'Logbook',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.groups_outlined),
                  activeIcon: Icon(Icons.groups),
                  label: 'Community',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.insights_outlined),
                  activeIcon: Icon(Icons.insights),
                  label: 'Analytics',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.current,
    required this.onNavigate,
    this.onSignOut,
    this.name,
    this.designation,
    this.centre,
  });

  final String current;
  final void Function(String route) onNavigate;
  final Future<void> Function()? onSignOut;
  final String? name;
  final String? designation;
  final String? centre;

  @override
  Widget build(BuildContext context) {
    final isReviewer = designation == 'Reviewer';
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Color(0xFF0B5FFF),
                child: Icon(Icons.visibility, color: Colors.white),
              ),
              accountName: Text(name ?? 'Aravind Trainee'),
              accountEmail: Text(
                [
                  designation,
                  centre,
                ].where((e) => (e ?? '').isNotEmpty).join(' | '),
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEAF2FF), Color(0xFFF7F9FC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            if (isReviewer) ...[
              _item(
                context,
                Icons.assignment,
                'Profiles to Assess',
                '/reviewer/pending',
              ),
              _item(
                context,
                Icons.check_circle,
                'Profiles Reviewed',
                '/reviewer/reviewed',
              ),
              _item(context, Icons.person, 'Profile', '/profile'),
            ] else ...[
              _item(context, Icons.home, 'Dashboard', '/home'),
              _item(context, Icons.menu_book, 'Logbook', '/logbook'),
              _item(context, Icons.groups, 'Community', '/community'),
              _item(context, Icons.school, 'Teaching Library', '/teaching'),
              _item(context, Icons.person, 'Profile', '/profile'),
              _item(context, Icons.search, 'Global Search', '/search'),
              _item(context, Icons.insights, 'Analytics', '/analytics'),
              _item(
                context,
                Icons.rate_review,
                'Review Queue',
                '/review-queue',
              ),
              _item(context, Icons.archive, 'Storage Tools', '/storage-tools'),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFEF4444)),
              title: const Text(
                'Sign out',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
              onTap: () async {
                Navigator.pop(context);
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
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Color(0xFFEF4444)),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && onSignOut != null) {
                  await onSignOut!();
                  // Router will automatically redirect to /auth when session is null
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    final selected = current.startsWith(route);
    return ListTile(
      leading: Icon(icon, color: selected ? const Color(0xFF0B5FFF) : null),
      title: Text(label),
      selected: selected,
      onTap: () {
        Navigator.pop(context);
        onNavigate(route);
      },
    );
  }
}
