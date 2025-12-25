import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../features/auth/application/auth_controller.dart';
import 'router.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      setState(() {
        _showSplash = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    if (_showSplash) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: EyeSplashScreen(),
      );
    }

    if (!authState.initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

class EyeSplashScreen extends StatefulWidget {
  const EyeSplashScreen({super.key});

  @override
  State<EyeSplashScreen> createState() => _EyeSplashScreenState();
}

class _EyeSplashScreenState extends State<EyeSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _blinkAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _blinkAnim = Tween<double>(begin: 1, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.6, curve: Curves.easeInOut)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1e2a3a),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _EyePainter(_blinkAnim.value),
              size: const Size(180, 180),
            );
          },
        ),
      ),
    );
  }
}

class _EyePainter extends CustomPainter {
  final double blink;
  _EyePainter(this.blink);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final eyeRadius = size.width * 0.38;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    // Eye white
    canvas.drawOval(
      Rect.fromCenter(center: center, width: size.width * 0.8, height: size.height * blink * 0.8),
      paint,
    );
    // Iris
    paint.color = const Color(0xFF1e2a3a);
    canvas.drawCircle(center, eyeRadius * 0.7, paint);
    // Pupil
    paint.color = Colors.blueGrey[900]!;
    canvas.drawCircle(center, eyeRadius * 0.35, paint);
    // Eye highlight
    paint.color = Colors.white.withOpacity(0.7);
    canvas.drawCircle(center.translate(-eyeRadius * 0.2, -eyeRadius * 0.2), eyeRadius * 0.13, paint);
  }

  @override
  bool shouldRepaint(covariant _EyePainter oldDelegate) => oldDelegate.blink != blink;
}
