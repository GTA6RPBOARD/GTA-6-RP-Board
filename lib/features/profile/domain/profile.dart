enum UserPlatform { ps5, xbox, unknown }

class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    this.ingameName,
    this.platform = UserPlatform.unknown,
    this.deletedAt,
  });

  final String id;
  final String displayName;
  final String? ingameName;
  final UserPlatform platform;
  final DateTime? deletedAt;

  bool get isComplete =>
      (ingameName != null && ingameName!.isNotEmpty) &&
      platform != UserPlatform.unknown;

  factory Profile.fromMap(Map<String, dynamic> map) {
    final p = map['platform'] as String? ?? 'unknown';
    return Profile(
      id: map['id'] as String,
      displayName: (map['display_name'] as String?) ?? '',
      ingameName: map['ingame_name'] as String?,
      platform: UserPlatform.values.firstWhere(
        (e) => e.name == p,
        orElse: () => UserPlatform.unknown,
      ),
      deletedAt: map['deleted_at'] == null
          ? null
          : DateTime.tryParse(map['deleted_at'] as String),
    );
  }
}

final ingamePattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]{1,23}$');
