import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

class AuthStateModel {
  const AuthStateModel({
    required this.session,
    required this.isLoading,
    required this.errorMessage,
    required this.initialized,
  });

  final Session? session;
  final bool isLoading;
  final String? errorMessage;
  final bool initialized;

  factory AuthStateModel.initial() => const AuthStateModel(
    session: null,
    isLoading: false,
    errorMessage: null,
    initialized: false,
  );

  AuthStateModel copyWith({
    Session? session,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? initialized,
  }) {
    return AuthStateModel(
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      initialized: initialized ?? this.initialized,
    );
  }
}

class AuthController extends StateNotifier<AuthStateModel> {
  AuthController(this._repository) : super(AuthStateModel.initial()) {
    _hydrate();
  }

  final AuthRepository _repository;
  StreamSubscription<Session?>? _authSubscription;

  Future<void> _hydrate() async {
    final existingSession = _repository.currentSession;
    state = state.copyWith(session: existingSession, initialized: true);

    _authSubscription = _repository.onAuthStateChange.listen((session) {
      state = state.copyWith(
        session: session,
        isLoading: false,
        clearError: true,
        initialized: true,
      );
    });
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.signInWithGoogle();
    } on AuthException catch (error) {
      state = state.copyWith(errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Unexpected error. Please try again.',
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.signOut();
    } on AuthException catch (error) {
      state = state.copyWith(errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(errorMessage: 'Unable to sign out. Please retry.');
    } finally {
      state = state.copyWith(isLoading: false, session: null);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthStateModel>((ref) {
      final repository = ref.watch(authRepositoryProvider);
      return AuthController(repository);
    });
