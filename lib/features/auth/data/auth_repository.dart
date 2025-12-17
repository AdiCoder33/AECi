import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../core/supabase_client.dart';

class AuthRepository {
  AuthRepository(this._client);

  final supabase.SupabaseClient _client;

  supabase.Session? get currentSession => _client.auth.currentSession;

  Stream<supabase.Session?> get onAuthStateChange =>
      _client.auth.onAuthStateChange.map((event) => event.session);

  Future<void> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      supabase.OAuthProvider.google,
      redirectTo: _redirectUrl,
    );
  }

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  static const _redirectUrl = 'io.supabase.flutter://login-callback';

  Future<supabase.AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(email: email, password: password);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

final authStateChangesProvider = Provider<Stream<supabase.Session?>>(
  (ref) => ref.watch(authRepositoryProvider).onAuthStateChange,
);
