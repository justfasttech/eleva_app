import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_provider.dart';

class FaithHistoryEntry {
  final DateTime date;
  final int faithLevel;

  const FaithHistoryEntry({required this.date, required this.faithLevel});
}

final faithHistoryProvider =
    FutureProvider<List<FaithHistoryEntry>>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return [];

  final response = await Supabase.instance.client
      .from('faith_history')
      .select('faith_level, recorded_date')
      .eq('user_id', user.id)
      .order('recorded_date', ascending: false)
      .limit(10);

  final entries = (response as List)
      .map((row) => FaithHistoryEntry(
            date: DateTime.parse(row['recorded_date'] as String),
            faithLevel: row['faith_level'] as int,
          ))
      .toList()
      .reversed
      .toList();

  return entries;
});
