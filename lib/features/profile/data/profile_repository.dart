import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);
  final SupabaseClient _client;

  Future<Profile?> fetchMine() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await _client
        .from('users')
        .select('id, display_name, ingame_name, platform, deleted_at')
        .eq('id', uid)
        .maybeSingle();
    if (row == null) return null;
    return Profile.fromMap(row);
  }

  Future<Profile> updateMine({
    required String displayName,
    required String ingameName,
    required UserPlatform platform,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('not_authenticated');
    }
    final row = await _client
        .from('users')
        .update({
          'display_name': displayName.trim(),
          'ingame_name': ingameName.trim(),
          'platform': platform.name,
        })
        .eq('id', uid)
        .select('id, display_name, ingame_name, platform, deleted_at')
        .single();
    return Profile.fromMap(row);
  }
}
