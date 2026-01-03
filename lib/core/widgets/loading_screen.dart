import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  bool _showLoadingText = false;

  @override
  void initState() {
    super.initState();
    _initLaunchFlow();
  }

  Future<void> _initLaunchFlow() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool('launch_animation_shown') ?? false;
     final lastRoute = prefs.getString('last_route');

    String _resolveTargetRoute() {
      if (lastRoute != null &&
          lastRoute.isNotEmpty &&
          lastRoute != '/loading') {
        return lastRoute;
      }
      // Fall back to normal auth/home flow; router redirects as needed.
      return '/auth';
    }

    if (hasShown) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Skip GIF and go straight to where the user last was (or auth).
          GoRouter.of(context).go(_resolveTargetRoute());
        }
      });
      return;
    }

    await prefs.setBool('launch_animation_shown', true);

    // First-ever launch: show loading text after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showLoadingText = true;
        });
      }
    });

    // And navigate after 5 seconds on first launch only
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        GoRouter.of(context).go(_resolveTargetRoute());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // GIF animation (no card, no shadow, no border)
              SizedBox(
                width: 250,
                height: 250,
                child: Image.asset('assets/AppLaunch.gif', fit: BoxFit.cover),
              ),
              const SizedBox(height: 24),
              Text(
                'RetiNotes',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (_showLoadingText) ...[
                const SizedBox(height: 16),
                Text(
                  'Loading your RetiNotes...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    backgroundColor: const Color.fromRGBO(255, 255, 255, 1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
