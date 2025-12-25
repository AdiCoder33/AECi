import 'package:flutter/material.dart';
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF2FF), Color(0xFFF7F9FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Stack(
                  children: [
                    Positioned(
                      top: -30,
                      right: -50,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Card(
                      elevation: 10,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Color(0xFF0B5FFF),
                                  child: Icon(Icons.book, color: Colors.white),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Aravind E-Logbook',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: const [
                                Icon(Icons.verified_user, color: Color(0xFF0B5FFF)),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Sign in securely with your Aravind account',
                                    style: TextStyle(color: Color(0xFF475569)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            if (state.errorMessage != null) ...[
                              _ErrorBanner(message: state.errorMessage!),
                              const SizedBox(height: 12),
                            ],
                            _EmailPasswordFields(
                              emailController: emailController,
                              passwordController: passwordController,
                              isLoading: state.isLoading,
                              primaryLabel: isCreatingAccount
                                  ? 'Create account'
                                  : 'Continue with email',
                              onSubmit: () async {
                                final email = emailController.text.trim();
                                final password = passwordController.text;
                                if (email.isEmpty || password.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter both email and password.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final notifier = ref.read(
                                  authControllerProvider.notifier,
                                );
                                if (isCreatingAccount) {
                                  await notifier.signUpWithEmailPassword(
                                    email: email,
                                    password: password,
                                  );
                                  // After sign-up, check if we need to switch to sign-in mode
                                  final authState = ref.read(authControllerProvider);
                                  if (authState.session == null && 
                                      authState.errorMessage != null &&
                                      authState.errorMessage!.contains('created')) {
                                    // Switch back to sign-in mode for email confirmation flow
                                    if (mounted) {
                                      setState(() {
                                        isCreatingAccount = false;
                                      });
                                    }
                                  }
                                } else {
                                  notifier.signInWithEmailPassword(
                                    email: email,
                                    password: password,
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isCreatingAccount
                                      ? 'Have an account?'
                                      : 'Need an account?',
                                  style: const TextStyle(color: Color(0xFF475569)),
                                ),
                                TextButton(
                                  onPressed: state.isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            isCreatingAccount = !isCreatingAccount;
                                          });
                                        },
                                  child: Text(
                                    isCreatingAccount ? 'Sign in' : 'Create one',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),
                            _GoogleButton(isLoading: state.isLoading),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: const [
                                _FeaturePill(icon: Icons.note_alt, label: 'Log cases fast'),
                                _FeaturePill(icon: Icons.insights, label: 'Track analytics'),
                                _FeaturePill(icon: Icons.shield, label: 'Secure by Supabase'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
