class UserProfile {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;
  final double faithLevel;
  final String subscriptionStatus;
  final bool isAdmin;
  final bool onboardingCompleted;
  final String faithDescription;
  final double pendingFaith;

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    required this.faithLevel,
    required this.subscriptionStatus,
    required this.isAdmin,
    required this.onboardingCompleted,
    required this.faithDescription,
    required this.pendingFaith,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      faithLevel: (map['faith_level'] as num?)?.toDouble() ?? 0.0,
      subscriptionStatus: map['subscription_status'] as String? ?? 'free',
      isAdmin: map['is_admin'] as bool? ?? false,
      onboardingCompleted: map['onboarding_completed'] as bool? ?? false,
      faithDescription: map['faith_description'] as String? ?? '',
      pendingFaith: (map['pending_faith'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
