import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/scoring_word.dart';

final scoringWordsProvider = StreamProvider<List<ScoringWord>>((ref) {
  return Supabase.instance.client
      .from('scoring_words')
      .stream(primaryKey: ['id'])
      .order('points')
      .map((rows) => rows.map(ScoringWord.fromMap).toList());
});
