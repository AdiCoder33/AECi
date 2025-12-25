import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/profile/application/profile_controller.dart';
import '../features/profile/presentation/create_profile_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
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
import '../features/clinical_cases/presentation/case_form_screen.dart';
import '../features/clinical_cases/presentation/notifications_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final authChanges = ref.watch(authStateChangesProvider);
  final profileStream = ref.watch(profileChangesProvider);
  final profileState = ref.watch(profileControllerProvider);

  final refreshStream = StreamGroup.merge([authChanges, profileStream]);

  return GoRouter(
    initialLocation: '/auth',
    refreshListenable: GoRouterRefreshStream(refreshStream),
    redirect: (context, state) {
      final loggedIn = authState.session != null;
      final onAuthRoute = state.matchedLocation == '/auth';
      final onCreateProfile = state.matchedLocation == '/profile/create';
      final onProfileView = state.matchedLocation == '/profile';
      final hasProfile = profileState.profile != null;

      if (!authState.initialized) {
        return null;
      }

      if (loggedIn && !profileState.initialized) {
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

      if (loggedIn && hasProfile && onProfileView && !onAuthRoute) {
        return null;
      }

      return null;
    },
    routes: [
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
            name: profile?.name,
            designation: profile?.designation,
            centre: profile?.centre,
            onSignOut: authNotifier.signOut,
            child: child,
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
            builder: (context, state) => const LogbookScreen(),
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
            builder: (context, state) => const GlobalSearchScreen(),
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
                builder: (context, state) => const ClinicalCaseFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'caseDetail',
                builder: (context, state) => ClinicalCaseDetailScreen(
                  caseId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'notifications',
                name: 'notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
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
    this.onSignOut,
  });

  final Widget child;
  final String location;
  final String? name;
  final String? designation;
  final String? centre;
  final VoidCallback? onSignOut;

  int get _index {
    if (location.startsWith('/logbook')) return 1;
    if (location.startsWith('/cases')) return 2;
    if (location.startsWith('/teaching')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int i) {
    switch (i) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/logbook');
        break;
      case 2:
        context.go('/cases');
        break;
      case 3:
        context.go('/teaching');
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Logbook'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Cases'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Teaching'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
  final VoidCallback? onSignOut;
  final String? name;
  final String? designation;
  final String? centre;

  @override
  Widget build(BuildContext context) {
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
                [designation, centre].where((e) => (e ?? '').isNotEmpty).join(' • '),
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEAF2FF), Color(0xFFF7F9FC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            _item(context, Icons.home, 'Dashboard', '/home'),
            _item(context, Icons.book, 'Logbook', '/logbook'),
            _item(context, Icons.list_alt, 'Cases', '/cases'),
            _item(context, Icons.school, 'Teaching Library', '/teaching'),
            _item(context, Icons.person, 'Profile', '/profile'),
            _item(context, Icons.search, 'Global Search', '/search'),
            _item(context, Icons.insights, 'Analytics', '/analytics'),
            _item(context, Icons.rate_review, 'Review Queue', '/review-queue'),
            _item(context, Icons.archive, 'Storage Tools', '/storage-tools'),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () {
                Navigator.pop(context);
                onSignOut?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, String route) {
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
