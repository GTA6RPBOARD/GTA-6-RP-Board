import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseProvider));
});

final myProfileProvider = FutureProvider<Profile?>((ref) async {
  ref.watch(currentUserProvider);
  return ref.watch(profileRepositoryProvider).fetchMine();
});

class ProfileFormState {
  const ProfileFormState({this.saving = false, this.error, this.saved = false});
  final bool saving;
  final String? error;
  final bool saved;

  ProfileFormState copyWith({
    bool? saving,
    String? error,
    bool? saved,
    bool clearError = false,
  }) {
    return ProfileFormState(
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
      saved: saved ?? this.saved,
    );
  }
}

final profileFormProvider =
    NotifierProvider<ProfileFormController, ProfileFormState>(
  ProfileFormController.new,
);

class ProfileFormController extends Notifier<ProfileFormState> {
  @override
  ProfileFormState build() => const ProfileFormState();

  Future<bool> save({
    required String displayName,
    required String ingameName,
    required UserPlatform platform,
  }) async {
    state = state.copyWith(saving: true, saved: false, clearError: true);
    try {
      await ref.read(profileRepositoryProvider).updateMine(
            displayName: displayName,
            ingameName: ingameName,
            platform: platform,
          );
      ref.invalidate(myProfileProvider);
      state = state.copyWith(saving: false, saved: true);
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
      return false;
    }
  }
}
