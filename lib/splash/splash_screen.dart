import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/application/auth_controller.dart';

/// Premium medical-grade splash screen for ophthalmology e-Logbook
/// Features: Eye logo with book pupil, single natural blink animation
/// Duration: 1.8s total, clean medical UI aesthetic
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _blinkAnimation;
  late Animation<double> _bookScaleAnimation;
  late Animation<double> _ringRotationAnimation;
  late Animation<double> _circleMorphAnimation;
  late Animation<double> _circleExpandAnimation;

  @override
  void initState() {
    super.initState();

    // Single controller for entire 10.0s animation sequence (extended for visibility)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 10000),
      vsync: this,
    );

    // 1. Fade-in logo (0-300ms)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.167, curve: Curves.easeInOut), // 0-300ms
      ),
    );

    // 2. Eye blink animation (400-1000ms) - single natural blink
    _blinkAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 1.0,
              end: 0.1,
            ).chain(CurveTween(curve: Curves.easeInOut)),
            weight: 50.0, // Close eye
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 0.1,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeInOut)),
            weight: 50.0, // Open eye
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(
              0.222,
              0.556,
              curve: Curves.easeInOut,
            ), // 400-1000ms
          ),
        );

    // 3. Book icon scale during blink (400-1000ms)
    _bookScaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 1.0,
              end: 0.9,
            ).chain(CurveTween(curve: Curves.easeInOut)),
            weight: 50.0,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 0.9,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeInOut)),
            weight: 50.0,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(
              0.222,
              0.556,
              curve: Curves.easeInOut,
            ), // 400-1000ms
          ),
        );

    // 4. Circular rings subtle rotation during blink (400-1000ms)
    _ringRotationAnimation = Tween<double>(begin: 0.0, end: 0.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.222,
          0.556,
          curve: Curves.easeInOut,
        ), // 400-1000ms
      ),
    );

    // 5. Eye outline morphs into circle (1000-1400ms)
    _circleMorphAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.556,
          0.778,
          curve: Curves.easeInOut,
        ), // 1000-1400ms
      ),
    );

    // 6. Circle expands horizontally (1400-1800ms)
    _circleExpandAnimation = Tween<double>(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.778,
          1.0,
          curve: Curves.easeInOut,
        ), // 1400-1800ms
      ),
    );

    // Start animation and navigate after both conditions
    _controller.forward();
    Future.wait([
      Future.delayed(const Duration(seconds: 10)),
      _waitForAuthInitialized(),
    ]).then((_) {
      if (mounted) context.go('/auth');
    });
  }

  Future<void> _waitForAuthInitialized() async {
    // Wait until auth is initialized
    while (true) {
      await Future.delayed(const Duration(milliseconds: 100));
      final authState = ref.read(authControllerProvider);
      if (authState.initialized) break;
    }
  }

  /// Navigate to HomeScreen with smooth fade + scale transition
  void _navigateToHome() {
    if (!mounted) return;
    context.go(
      '/auth',
    ); // Navigate to auth, router will handle redirect to home if logged in
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Clean light grey background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Debug text to confirm splash is showing
            const Text(
              'AECi E-Logbook',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B5FFF),
              ),
            ),
            const SizedBox(height: 40),
            // Animated logo
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Circular rings (device/watch frame)
                        _buildCircularRings(),

                        // Eye outline
                        _buildEyeOutline(),

                        // Book icon (pupil)
                        _buildBookPupil(),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Color(0xFF0B5FFF)),
          ],
        ),
      ),
    );
  }

  /// Build circular rings with subtle rotation
  Widget _buildCircularRings() {
    return Transform.rotate(
      angle: _ringRotationAnimation.value * math.pi,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF0B5FFF).withOpacity(0.15),
                width: 2,
              ),
            ),
          ),
          // Inner ring
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF0B5FFF).withOpacity(0.10),
                width: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build eye outline with blink and morph animations
  Widget _buildEyeOutline() {
    // Calculate morph progress
    final morphProgress = _circleMorphAnimation.value;
    final expandProgress = _circleExpandAnimation.value;

    // Eye shape parameters
    final width = 140.0 * expandProgress;
    final height = 80.0 * _blinkAnimation.value;

    // Morph from eye to circle
    final effectiveWidth = morphProgress < 1.0
        ? width + (80.0 - width) * morphProgress * expandProgress
        : width;
    final effectiveHeight = morphProgress < 1.0
        ? height + (80.0 - height) * morphProgress
        : 80.0 * expandProgress;

    return Container(
      width: effectiveWidth,
      height: effectiveHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: morphProgress < 1.0
            ? BorderRadius.circular(60) // Eye shape
            : BorderRadius.circular(80), // Circle shape
        border: Border.all(
          color: const Color(0xFF0B5FFF).withOpacity(0.6),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B5FFF).withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
    );
  }

  /// Build book icon (pupil) with scale animation
  Widget _buildBookPupil() {
    return Transform.scale(
      scale: _bookScaleAnimation.value,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF0B5FFF),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B5FFF).withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.menu_book_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
