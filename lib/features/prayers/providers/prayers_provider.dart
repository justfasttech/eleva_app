import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/prayer.dart';

final prayersProvider = StreamProvider<List<Prayer>>((ref) {
  return Supabase.instance.client
      .from('prayers')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows.map(Prayer.fromMap).toList());
});

final prayersByThemeProvider =
    Provider.family<AsyncValue<List<Prayer>>, String?>((ref, themeId) {
  final allPrayers = ref.watch(prayersProvider);
  if (themeId == null) return allPrayers;
  return allPrayers.whenData(
    (prayers) => prayers.where((p) => p.themeId == themeId).toList(),
  );
});
