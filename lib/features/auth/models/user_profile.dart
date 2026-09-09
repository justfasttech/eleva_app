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
  final DateTime? trialStartDate;
  final DateTime? subscriptionEndDate;
  final String? revenuecatId;

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
    this.trialStartDate,
    this.subscriptionEndDate,
    this.revenuecatId,
  });

  bool get isTrialActive {
    final trialEnd = createdAt.add(const Duration(days: 30));
    return DateTime.now().isBefore(trialEnd);
  }

  bool get isPremium => subscriptionStatus == 'premium' || isTrialActive;

  int get trialDaysRemaining {
    final trialEnd = createdAt.add(const Duration(days: 30));
    final remaining = trialEnd.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

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
      trialStartDate: map['trial_start_date'] != null
          ? DateTime.parse(map['trial_start_date'] as String)
          : null,
      subscriptionEndDate: map['subscription_end_date'] != null
          ? DateTime.parse(map['subscription_end_date'] as String)
          : null,
      revenuecatId: map['revenuecat_id'] as String?,
    );
  }
}
