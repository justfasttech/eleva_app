import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/daily_task.dart';

final allTasksProvider = StreamProvider<List<DailyTask>>((ref) {
  return Supabase.instance.client
      .from('daily_tasks')
      .stream(primaryKey: ['id'])
      .order('created_at')
      .map((rows) => rows.map((r) => DailyTask.fromMap(r)).toList());
});

final dailyTasksProvider = StreamProvider<List<DailyTask>>((ref) {
  final all = ref.watch(allTasksProvider);
  return all.when(
    data: (tasks) => Stream.value(tasks.where((t) => t.isDaily).toList()),
    loading: () => const Stream.empty(),
    error: (e, s) => Stream.error(e, s),
  );
});

final weeklyTasksProvider = StreamProvider<List<DailyTask>>((ref) {
  final all = ref.watch(allTasksProvider);
  return all.when(
    data: (tasks) => Stream.value(tasks.where((t) => t.isWeekly).toList()),
    loading: () => const Stream.empty(),
    error: (e, s) => Stream.error(e, s),
  );
});
