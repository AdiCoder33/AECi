import 'package:flutter/material.dart';
// No direct navigation here; let the router and loading screen control flow.
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to loading screen after a brief delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        GoRouter.of(context).go('/loading');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(228, 237, 255, 1),
              Color.fromARGB(255, 235, 236, 243),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Image.asset('assets/logo.png', width: 200, height: 200),
        ),
      ),
    );
  }
}
