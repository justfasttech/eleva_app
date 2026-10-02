import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/diary_entry.dart';

final hasFilledDiaryTodayProvider = Provider<bool>((ref) {
  final entries = ref.watch(diaryEntriesProvider).value ?? [];
  if (entries.isEmpty) return false;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return entries.any((e) {
    final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
    return d == today;
  });
});

final diaryEntriesProvider = StreamProvider<List<DiaryEntry>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return Stream.value([]);

  return Supabase.instance.client
      .from('diary_entries')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .map((rows) => rows.map(DiaryEntry.fromMap).toList());
});
