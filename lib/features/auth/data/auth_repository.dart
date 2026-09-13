import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/supabase/env.dart';

class AuthRepository {
  AuthRepository(this._client);
  final SupabaseClient _client;

  Future<void> signInEmail(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpEmail(String email, String password) {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<void> signInOAuth(OAuthProvider provider) {
    return _client.auth.signInWithOAuth(
      provider,
      redirectTo: AppEnv.oauthRedirect,
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  String mapError(Object error, S s) {
    if (error is AuthException) {
      final m = error.message.toLowerCase();
      if (m.contains('invalid login') || m.contains('invalid_credentials')) {
        return s.authFailed;
      }
      if (m.contains('network') || m.contains('failed host')) {
        return s.networkError;
      }
      if (error.statusCode == '400' && m.contains('password')) {
        return s.weakPassword;
      }
      return error.message;
    }
    return s.authFailed;
  }
}
