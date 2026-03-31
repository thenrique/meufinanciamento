class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.isPremium,
    this.avatarUrl,
    this.notificationsEnabled = true,
  });

  final String id;
  final String name;
  final String email;
  final bool isPremium;
  final String? avatarUrl;
  final bool notificationsEnabled;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['full_name'] as String? ?? '',
      email: json['email'] as String,
      isPremium: json['is_premium'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String?,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'is_premium': isPremium,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'notifications_enabled': notificationsEnabled,
      };

  UserProfile copyWith({
    String? name,
    bool? isPremium,
    String? avatarUrl,
    bool? notificationsEnabled,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email,
      isPremium: isPremium ?? this.isPremium,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
