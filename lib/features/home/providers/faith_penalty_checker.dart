import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/user_profile_provider.dart';
import 'faith_history_provider.dart';
import 'faith_history_recorder.dart';

class FaithPenaltyChecker {
  static Future<String?> check(WidgetRef ref) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final messages = <String>[];

    final inactivityPenalty = await _checkInactivity(prefs, today, user.id);
    if (inactivityPenalty != null) messages.add(inactivityPenalty);

    final diaryPenalty = await _checkDiaryAbsence(prefs, today, user.id);
    if (diaryPenalty != null) messages.add(diaryPenalty);

    await prefs.setString('last_active_date', today);

    if (messages.isNotEmpty) {
      ref.invalidate(userProfileProvider);
      ref.invalidate(faithHistoryProvider);
    }

    return messages.isEmpty ? null : messages.join('\n');
  }

  static Future<String?> _checkInactivity(SharedPreferences prefs, String today, String userId) async {
    final lastActive = prefs.getString('last_active_date');
    if (lastActive == null) return null;

    final lastDate = DateTime.tryParse(lastActive);
    if (lastDate == null) return null;

    final daysDiff = DateTime.now().difference(lastDate).inDays;
    if (daysDiff < 3) return null;

    final penaltyKey = 'inactivity_penalty_$today';
    if (prefs.getBool(penaltyKey) == true) return null;

    await _applyPenalty(userId, -3);
    await prefs.setBool(penaltyKey, true);

    return 'Você perdeu 3 pontos de fé por $daysDiff dias de inatividade';
  }

  static Future<String?> _checkDiaryAbsence(SharedPreferences prefs, String today, String userId) async {
    final penaltyKey = 'diary_penalty_$today';
    if (prefs.getBool(penaltyKey) == true) return null;

    final lastPenaltyDate = prefs.getString('last_diary_penalty_date');
    if (lastPenaltyDate != null) {
      final lastPenalty = DateTime.tryParse(lastPenaltyDate);
      if (lastPenalty != null && DateTime.now().difference(lastPenalty).inDays < 7) {
        return null;
      }
    }

    try {
      final entries = await Supabase.instance.client
          .from('diary_entries')
          .select('created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if (entries.isEmpty) return null;

      final lastEntry = DateTime.parse(entries[0]['created_at'] as String);
      final daysSince = DateTime.now().difference(lastEntry).inDays;

      if (daysSince < 7) return null;

      await _applyPenalty(userId, -5);
      await prefs.setBool(penaltyKey, true);
      await prefs.setString('last_diary_penalty_date', today);

      return 'Você perdeu 5 pontos de fé por $daysSince dias sem reflexão';
    } catch (_) {
      return null;
    }
  }

  static Future<void> _applyPenalty(String userId, int amount) async {
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('faith_level, pending_faith')
        .eq('id', userId)
        .single();

    final currentFaith = (profile['faith_level'] as int?) ?? 0;
    final currentPending = (profile['pending_faith'] as int?) ?? 0;
    final newPending = currentPending + amount;
    final projectedFaith = (currentFaith + newPending).clamp(0, 70);

    await Supabase.instance.client
        .from('profiles')
        .update({'pending_faith': newPending})
        .eq('id', userId);

    await recordFaithSnapshot(userId, projectedFaith);
  }
}
