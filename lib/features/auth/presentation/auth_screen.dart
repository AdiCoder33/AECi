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
      backgroundColor: const Color.fromARGB(245, 255, 255, 255),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // GIF above app name
                SizedBox(
                  height: 110,
                  child: Image.asset(
                    'assets/AppLaunch.gif',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                // App Name
                const Text(
                  'RetiNotes',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B5FFF),
                  ),
                ),
                const SizedBox(height: 8),
                // Tagline
                const Text(
                  'Sign in securely with your Aravind account',
                  style: TextStyle(fontSize: 16, color: Color(0xFF475569)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Card with form
                Card(
                  elevation: 8,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.errorMessage != null) ...[
                          _ErrorBanner(message: state.errorMessage!),
                          const SizedBox(height: 12),
                        ],
                        _EmailPasswordFields(
                          emailController: emailController,
                          passwordController: passwordController,
                          isLoading: state.isLoading,
                          primaryLabel: isCreatingAccount
                              ? 'Create Account'
                              : 'Sign In',
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
                              final authState = ref.read(
                                authControllerProvider,
                              );
                              if (authState.session == null &&
                                  authState.errorMessage != null &&
                                  authState.errorMessage!.contains('created')) {
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
                                isCreatingAccount
                                    ? 'Sign In'
                                    : 'Create Account',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: const [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'or continue with',
                                style: TextStyle(color: Color(0xFF475569)),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _GoogleButton(isLoading: state.isLoading),
                      ],
                    ),
                  ),
                ),
              ],
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 29, 114, 250),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(primaryLabel),
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
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: isLoading
                ? null
                : () => ref
                      .read(authControllerProvider.notifier)
                      .signInWithGoogle(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF4285F4),
                            ),
                          ),
                        )
                      : Image.asset(
                          'assets/google_logo.png',
                          height: 24,
                          width: 24,
                        ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      isLoading ? 'Signing in...' : 'Google',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF4285F4),
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
