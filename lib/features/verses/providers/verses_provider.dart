import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/daily_verse.dart';

final dailyVersesProvider = StreamProvider<List<DailyVerse>>((ref) {
  return Supabase.instance.client
      .from('daily_verses')
      .stream(primaryKey: ['id'])
      .order('created_at')
      .map((rows) => rows.map((r) => DailyVerse.fromMap(r)).toList());
});

final todayVerseProvider = Provider<DailyVerse?>((ref) {
  final verses = ref.watch(dailyVersesProvider).value ?? [];
  final active = verses.where((v) => v.isActive).toList();
  if (active.isEmpty) return null;

  final now = DateTime.now();
  final seed = now.year * 10000 + now.month * 100 + now.day;
  final index = Random(seed).nextInt(active.length);
  return active[index];
});
