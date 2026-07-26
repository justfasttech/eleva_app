import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/diary_entry.dart';

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
