import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/community_repository.dart';
import '../../profile/data/profile_model.dart';

const communityDesignationOrder = [
  'Consultant',
  'Fellow',
  'Resident',
];

final communityFilterProvider = StateProvider<String>((ref) => 'All');

final communityProfilesProvider =
    FutureProvider.autoDispose<List<Profile>>((ref) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.listProfiles();
});

final communityProfileProvider =
    FutureProvider.family.autoDispose<Profile?, String>((ref, id) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getProfile(id);
});
