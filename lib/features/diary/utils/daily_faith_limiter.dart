import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _kGainToday = 'faith_gain_today';
const _kGainDate = 'faith_gain_date';
const _kLossToday = 'faith_loss_today';
const _kLossDate = 'faith_loss_date';

Future<double> _loadLimit(String key, double fallback) async {
  try {
    final rows = await Supabase.instance.client
        .from('app_config')
        .select('value')
        .eq('key', key)
        .limit(1);
    if (rows.isNotEmpty) {
      return double.tryParse(rows[0]['value'] as String) ?? fallback;
    }
  } catch (_) {}
  return fallback;
}

Future<double> applyFaithWithDailyLimit(String userId, double score) async {
  if (score == 0) return 0;

  final prefs = await SharedPreferences.getInstance();
  final today = DateTime.now().toIso8601String().substring(0, 10);

  final isGain = score > 0;

  final limitKey = isGain ? 'daily_faith_limit' : 'daily_faith_loss_limit';
  final todayKey = isGain ? _kGainToday : _kLossToday;
  final dateKey = isGain ? _kGainDate : _kLossDate;
  final fallback = isGain ? 10.0 : 10.0;

  final limit = await _loadLimit(limitKey, fallback);

  final savedDate = prefs.getString(dateKey) ?? '';
  double usedToday = savedDate == today ? (prefs.getDouble(todayKey) ?? 0) : 0;

  final remaining = limit - usedToday;
  if (remaining <= 0) return 0;

  double capped = score.abs();
  if (capped > remaining) {
    capped = remaining;
  }

  final applied = isGain ? capped : -capped;

  await Supabase.instance.client.rpc('apply_faith_penalty', params: {
    'p_user_id': userId,
    'p_amount': applied,
  });

  await prefs.setDouble(todayKey, usedToday + capped);
  await prefs.setString(dateKey, today);

  return applied;
}
