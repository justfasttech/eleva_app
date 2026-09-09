import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/user_profile_provider.dart';

final isPremiumProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  return profile?.isPremium ?? false;
});

final trialDaysRemainingProvider = Provider<int>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  return profile?.trialDaysRemaining ?? 0;
});

final isTrialActiveProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  return profile?.isTrialActive ?? false;
});

final subscriptionStatusProvider = Provider<String>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  return profile?.subscriptionStatus ?? 'free';
});
