import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/application/auth_controller.dart';
import '../data/profile_model.dart';
import '../data/profile_repository.dart';

class ProfileState {
  const ProfileState({
    required this.profile,
    required this.isLoading,
    required this.errorMessage,
    required this.initialized,
  });

  final Profile? profile;
  final bool isLoading;
  final String? errorMessage;
  final bool initialized;

  factory ProfileState.initial() => const ProfileState(
    profile: null,
    isLoading: false,
    errorMessage: null,
    initialized: false,
  );

  ProfileState copyWith({
    Profile? profile,
    bool clearProfile = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? initialized,
  }) {
    return ProfileState(
      profile: clearProfile ? null : profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      initialized: initialized ?? this.initialized,
    );
  }
}

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this._ref, this._repository)
    : super(ProfileState.initial()) {
    _listenAuth();
    _initialLoad();
  }

  final Ref _ref;
  final ProfileRepository _repository;
  StreamSubscription<Profile?>? _profileStream;

  void _listenAuth() {
    _ref.listen<AuthStateModel>(authControllerProvider, (previous, next) {
      if (next.session == null) {
        _profileStream?.cancel();
        state = ProfileState.initial().copyWith(initialized: true);
      } else if (previous?.session?.user.id != next.session!.user.id) {
        _startProfileStream();
      }
    }, fireImmediately: true);
  }

  Future<void> _initialLoad() async {
    final authState = _ref.read(authControllerProvider);
    if (authState.session == null) {
      state = state.copyWith(initialized: true);
      return;
    }
    await loadProfile();
    _startProfileStream();
  }

  void _startProfileStream() {
    _profileStream?.cancel();
    final stream = _repository.watchMyProfile();
    _profileStream = stream.listen((profile) {
      state = state.copyWith(
        profile: profile,
        isLoading: false,
        clearError: true,
        initialized: true,
      );
    });
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _repository.getMyProfile();
      state = state.copyWith(profile: profile, initialized: true);
    } on AuthException catch (error) {
      state = state.copyWith(errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(errorMessage: 'Unable to load profile.');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> upsertProfile(Profile profile) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.upsertMyProfile(profile);
      state = state.copyWith(profile: profile);
    } on AuthException catch (error) {
      state = state.copyWith(errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Unable to save profile. Please try again.',
      );
    } finally {
      state = state.copyWith(isLoading: false, initialized: true);
    }
  }

  @override
  void dispose() {
    _profileStream?.cancel();
    super.dispose();
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
      final repository = ref.watch(profileRepositoryProvider);
      return ProfileController(ref, repository);
    });

final profileChangesProvider = Provider<Stream<Profile?>>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.watchMyProfile();
});
