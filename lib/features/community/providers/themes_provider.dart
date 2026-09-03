import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/post_theme.dart';

final postThemesProvider = StreamProvider<List<PostTheme>>((ref) {
  return Supabase.instance.client
      .from('post_themes')
      .stream(primaryKey: ['id'])
      .order('name')
      .map((rows) => rows.map(PostTheme.fromMap).toList());
});
