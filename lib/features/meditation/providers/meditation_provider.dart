import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/meditation.dart';

final meditationsProvider = StreamProvider<List<Meditation>>((ref) {
  return Supabase.instance.client
      .from('meditations')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows.map(Meditation.fromMap).toList());
});

final meditationsByThemeProvider =
    Provider.family<AsyncValue<List<Meditation>>, String?>((ref, themeId) {
  final allMeditations = ref.watch(meditationsProvider);
  if (themeId == null) return allMeditations;
  return allMeditations.whenData(
    (meditations) => meditations.where((m) => m.themeId == themeId).toList(),
  );
});
