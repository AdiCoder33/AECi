import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../core/supabase_client.dart';

class AuthRepository {
  AuthRepository(this._client);

  final supabase.SupabaseClient _client;
  
  // Initialize GoogleSignIn with client ID for web
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    clientId: const String.fromEnvironment(
      'GOOGLE_WEB_CLIENT_ID',
      defaultValue: '362737514668-ejdc1dvss4j3r9l7negebv1dfn7gto64.apps.googleusercontent.com',
    ),
  );

  supabase.Session? get currentSession => _client.auth.currentSession;

  Stream<supabase.Session?> get onAuthStateChange =>
      _client.auth.onAuthStateChange.map((event) => event.session);

  Future<void> signInWithGoogle() async {
    try {
      // Sign out first to show account picker every time
      await _googleSignIn.signOut();
      
      // Trigger the Google Sign-In flow (shows account picker)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw supabase.AuthException('Sign in cancelled by user');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw supabase.AuthException('Failed to get Google authentication tokens');
      }

      // Sign in to Supabase with Google tokens
      await _client.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } on supabase.AuthException {
      rethrow;
    } catch (e) {
      // Error 12500 = SHA-1 certificate fingerprint not configured
      // Error 10 = Developer error (package name or SHA-1 mismatch)
      print('Google Sign-In Error: $e');
      throw supabase.AuthException(
        'Google Sign-In failed. Please check:\n'
        '1. Android OAuth Client created in Google Cloud Console\n'
        '2. SHA-1 fingerprint matches your debug/release keystore\n'
        '3. Package name is correct: com.example.aravind_e_logbook\n'
        'Error details: ${e.toString()}'
      );
    }
  }

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    // Sign out from Google first
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore Google sign-out errors
    }
    // Then sign out from Supabase
    await _client.auth.signOut();
  }

  static const _redirectUrl = 'io.supabase.flutter://login-callback';

  Future<supabase.AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: _redirectUrl,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

final authStateChangesProvider = Provider<Stream<supabase.Session?>>(
  (ref) => ref.watch(authRepositoryProvider).onAuthStateChange,
);
