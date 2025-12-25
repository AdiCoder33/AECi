
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  bool isCreatingAccount = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Animated circular bars background
          const _AnimatedCircleBars(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(238, 252, 252, 254),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 91, 138, 247).withOpacity(0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          isCreatingAccount ? 'Register' : 'Login',
                          style: const TextStyle(
                            color: Color(0xFFFFA500),
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (state.errorMessage != null) ...[
                        _ErrorBanner(message: state.errorMessage!),
                        const SizedBox(height: 12),
                      ],
                      _EmailPasswordFields(
                        emailController: emailController,
                        passwordController: passwordController,
                        isLoading: state.isLoading,
                        primaryLabel: isCreatingAccount ? 'Sign Up' : 'Login',
                        onSubmit: () {
                          final email = emailController.text.trim();
                          final password = passwordController.text;
                          if (email.isEmpty || password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter both email and password.'),
                              ),
                            );
                            return;
                          }
                          final notifier = ref.read(authControllerProvider.notifier);
                          if (isCreatingAccount) {
                            notifier.signUpWithEmailPassword(email: email, password: password);
                          } else {
                            notifier.signInWithEmailPassword(email: email, password: password);
                          }
                        },
                      ),
                      const SizedBox(height: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Forgot your password?',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      // Removed duplicate Login button
                      const SizedBox(height: 1),
                      Center(
                        child: Text(
                          'log in with',
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialIcon(
                            color: const Color(0xFFdb4437),
                            icon: Icons.g_mobiledata,
                            onTap: () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Center(
                        child: GestureDetector(
                          onTap: state.isLoading
                              ? null
                              : () {
                                  setState(() {
                                    isCreatingAccount = !isCreatingAccount;
                                  });
                                },
                          child: Text(
                            isCreatingAccount ? 'Already have an account? Sign In' : "Don't have an account? Sign Up",
                            style: const TextStyle(
                              color: Color(0xFFFFA500),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
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
        ],
      ),
    );
  }
}

// Animated circular bars background widget
class _AnimatedCircleBars extends StatefulWidget {
  const _AnimatedCircleBars();

  @override
  State<_AnimatedCircleBars> createState() => _AnimatedCircleBarsState();
}

class _AnimatedCircleBarsState extends State<_AnimatedCircleBars> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  static const int numBars = 50;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _CircleBarsPainter(_controller.value),
          );
        },
      ),
    );
  }
}

class _CircleBarsPainter extends CustomPainter {
  final double progress;
  static const int numBars = 50;
  _CircleBarsPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2.2;
    for (int i = 0; i < numBars; i++) {
      final angle = (2 * math.pi * i / numBars) + (progress * 2 * math.pi);
      final barLength = 35.0;
      final barWidth = 8.0;
      final isActive = i == (progress * numBars).floor() % numBars;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..strokeCap = StrokeCap.round;
      if (isActive) {
        paint.shader = const LinearGradient(colors: [Color(0xFFFFA500), Color(0xFFFF8C00)])
            .createShader(Rect.fromLTWH(0, 0, barWidth, barLength));
      } else {
        paint.color = const Color(0xFF4a5f7f);
      }
      final barCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.save();
      canvas.translate(barCenter.dx, barCenter.dy);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(0, -barLength / 2), width: barWidth, height: barLength),
          const Radius.circular(4),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CircleBarsPainter oldDelegate) => oldDelegate.progress != progress;
}

class _SocialIcon extends StatelessWidget {
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  const _SocialIcon({required this.color, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _EmailPasswordFields extends StatelessWidget {
  const _EmailPasswordFields({
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.primaryLabel,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final String primaryLabel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'name@aravind.org',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          enabled: !isLoading,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          enabled: !isLoading,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : Text(
                    primaryLabel,
                    style: const TextStyle(color: Colors.black),
                  ),
          ),
        ),
      ],
    );
  }
}

class _GoogleButton extends ConsumerWidget {
  const _GoogleButton({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: isLoading
          ? null
          : () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
      icon: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black,
              ),
            )
          : const Icon(Icons.login, color: Colors.black),
      label: Text(
        isLoading ? 'Signing in...' : 'Continue with Google',
        style: const TextStyle(color: Colors.black),
      ),
      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.15),
        border: Border.all(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF0B5FFF), size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
