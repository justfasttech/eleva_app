import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final appConfigProvider = StreamProvider<Map<String, String>>((ref) {
  return Supabase.instance.client
      .from('app_config')
      .stream(primaryKey: ['key'])
      .map((rows) {
    final config = <String, String>{};
    for (final row in rows) {
      config[row['key'] as String] = row['value'] as String;
    }
    return config;
  });
});

final diaryPenaltyProvider = Provider<double>((ref) {
  final config = ref.watch(appConfigProvider).value ?? {};
  return double.tryParse(config['diary_penalty'] ?? '') ?? -5.0;
});

final inactivityPenaltyProvider = Provider<double>((ref) {
  final config = ref.watch(appConfigProvider).value ?? {};
  return double.tryParse(config['inactivity_penalty'] ?? '') ?? -3.0;
});
