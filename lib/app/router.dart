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
        builder: (context, state, child) =>
            _MainShell(location: state.matchedLocation, child: child),
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
  const _MainShell({required this.child, required this.location});

  final Widget child;
  final String location;

  int get _index {
    if (location.startsWith('/logbook')) return 1;
    if (location.startsWith('/profile')) return 2;
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
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => _onTap(context, i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Logbook'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
