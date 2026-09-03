import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> recordFaithSnapshot(String userId, double faithLevel) async {
  final today = DateTime.now().toIso8601String().substring(0, 10);
  await Supabase.instance.client.from('faith_history').upsert(
    {
      'user_id': userId,
      'faith_level': faithLevel,
      'recorded_date': today,
    },
    onConflict: 'user_id,recorded_date',
  );
}
