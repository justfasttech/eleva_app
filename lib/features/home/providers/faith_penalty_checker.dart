import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/user_profile_provider.dart';
import 'faith_history_provider.dart';
import 'faith_history_recorder.dart';

class FaithPenaltyChecker {
  static Future<Map<String, double>> _loadPenaltyConfig() async {
    try {
      final rows = await Supabase.instance.client
          .from('app_config')
          .select('key, value')
          .inFilter('key', ['diary_penalty', 'inactivity_penalty']);
      final config = <String, double>{};
      for (final row in rows) {
        config[row['key'] as String] =
            double.tryParse(row['value'] as String) ?? 0;
      }
      return config;
    } catch (_) {
      return {};
    }
  }

  static Future<void> check(WidgetRef ref) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final config = await _loadPenaltyConfig();
    final inactivityPenalty = config['inactivity_penalty'] ?? -3.0;
    final diaryPenalty = config['diary_penalty'] ?? -5.0;

    var applied = false;

    if (await _checkInactivity(prefs, today, user.id, inactivityPenalty)) {
      applied = true;
    }
    if (await _checkDiaryAbsence(prefs, today, user.id, diaryPenalty)) {
      applied = true;
    }

    await prefs.setString('last_active_date', today);

    if (applied) {
      ref.invalidate(userProfileProvider);
      ref.invalidate(faithHistoryProvider);
    }
  }

  static Future<bool> _checkInactivity(
      SharedPreferences prefs, String today, String userId, double penalty) async {
    final lastActive = prefs.getString('last_active_date');
    if (lastActive == null) return false;

    final lastDate = DateTime.tryParse(lastActive);
    if (lastDate == null) return false;

    final daysDiff = DateTime.now().difference(lastDate).inDays;
    if (daysDiff < 3) return false;

    final penaltyKey = 'inactivity_penalty_$today';
    if (prefs.getBool(penaltyKey) == true) return false;

    await _applyPenalty(userId, penalty);
    await prefs.setBool(penaltyKey, true);

    return true;
  }

  static Future<bool> _checkDiaryAbsence(
      SharedPreferences prefs, String today, String userId, double penalty) async {
    final penaltyKey = 'diary_penalty_$today';
    if (prefs.getBool(penaltyKey) == true) return false;

    final lastPenaltyDate = prefs.getString('last_diary_penalty_date');
    if (lastPenaltyDate != null) {
      final lastPenalty = DateTime.tryParse(lastPenaltyDate);
      if (lastPenalty != null && DateTime.now().difference(lastPenalty).inDays < 7) {
        return false;
      }
    }

    try {
      final entries = await Supabase.instance.client
          .from('diary_entries')
          .select('created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if (entries.isEmpty) return false;

      final lastEntry = DateTime.parse(entries[0]['created_at'] as String);
      final daysSince = DateTime.now().difference(lastEntry).inDays;

      if (daysSince < 7) return false;

      await _applyPenalty(userId, penalty);
      await prefs.setBool(penaltyKey, true);
      await prefs.setString('last_diary_penalty_date', today);

      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _applyPenalty(String userId, double amount) async {
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('faith_level, pending_faith')
        .eq('id', userId)
        .single();

    final currentFaith = (profile['faith_level'] as num?)?.toDouble() ?? 0.0;
    final currentPending = (profile['pending_faith'] as num?)?.toDouble() ?? 0.0;
    final newPending = currentPending + amount;
    final projectedFaith = (currentFaith + newPending).clamp(0.0, 70.0).toDouble();

    await Supabase.instance.client
        .from('profiles')
        .update({'pending_faith': newPending})
        .eq('id', userId);

    await recordFaithSnapshot(userId, projectedFaith);
  }
}
