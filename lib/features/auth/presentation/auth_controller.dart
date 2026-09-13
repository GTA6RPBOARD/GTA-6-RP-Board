import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/auth_repository.dart';

enum AuthMode { signIn, signUp }

class AuthUiState {
  const AuthUiState({
    this.mode = AuthMode.signIn,
    this.loading = false,
    this.error,
  });

  final AuthMode mode;
  final bool loading;
  final String? error;

  AuthUiState copyWith({
    AuthMode? mode,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return AuthUiState(
      mode: mode ?? this.mode,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseProvider));
});

final authControllerProvider =
    NotifierProvider<AuthController, AuthUiState>(AuthController.new);

class AuthController extends Notifier<AuthUiState> {
  @override
  AuthUiState build() => const AuthUiState();

  void toggleMode() {
    state = state.copyWith(
      mode: state.mode == AuthMode.signIn ? AuthMode.signUp : AuthMode.signIn,
      clearError: true,
    );
  }

  Future<bool> submit(String email, String password, String Function(Object) mapError) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final repo = ref.read(authRepositoryProvider);
      if (state.mode == AuthMode.signIn) {
        await repo.signInEmail(email, password);
      } else {
        await repo.signUpEmail(email, password);
      }
      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: mapError(e));
      return false;
    }
  }

  Future<void> oauth(OAuthProvider provider, String Function(Object) mapError) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).signInOAuth(provider);
      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: mapError(e));
    }
  }
}
