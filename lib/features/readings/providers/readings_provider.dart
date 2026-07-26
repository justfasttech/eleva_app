import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/spiritual_reading.dart';

final spiritualReadingsProvider = StreamProvider<List<SpiritualReading>>((ref) {
  return Supabase.instance.client
      .from('spiritual_readings')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows.map(SpiritualReading.fromMap).toList());
});

final readingsByCategoryProvider =
    Provider.family<AsyncValue<List<SpiritualReading>>, String?>((ref, category) {
  final allReadings = ref.watch(spiritualReadingsProvider);
  if (category == null) return allReadings;
  return allReadings.whenData(
    (readings) => readings.where((r) => r.category == category).toList(),
  );
});
