import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/user_profile_provider.dart';
import '../models/user_content_unlock.dart';

final userUnlocksProvider = StreamProvider<List<UserContentUnlock>>((ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return const Stream.empty();

  return Supabase.instance.client
      .from('user_content_unlocks')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .map((rows) => rows.map(UserContentUnlock.fromMap).toList());
});

final unlockedContentIdsProvider = Provider<Set<String>>((ref) {
  final unlocks = ref.watch(userUnlocksProvider);
  return unlocks.when(
    data: (list) => list.map((u) => u.contentId).toSet(),
    loading: () => {},
    error: (_, __) => {},
  );
});

final canUnlockTodayProvider =
    FutureProvider.family<bool, String>((ref, contentType) async {
  final profile = ref.watch(userProfileProvider).value;
  if (profile != null && profile.isPremium) return true;

  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return false;

  final tzOffset = DateTime.now().timeZoneOffset.inMinutes;

  final result = await Supabase.instance.client.rpc('can_unlock_today', params: {
    'p_user_id': userId,
    'p_content_type': contentType,
    'p_tz_offset_minutes': tzOffset,
  });

  return result as bool? ?? false;
});

Future<bool> unlockContent({
  required String contentType,
  required String contentId,
  required double faithPoints,
}) async {
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;

    final tzOffset = DateTime.now().timeZoneOffset.inMinutes;

    final result = await Supabase.instance.client.rpc('unlock_content', params: {
      'p_user_id': userId,
      'p_content_type': contentType,
      'p_content_id': contentId,
      'p_faith_points': faithPoints,
      'p_tz_offset_minutes': tzOffset,
    });

    return result as bool? ?? false;
  } catch (_) {
    return false;
  }
}
