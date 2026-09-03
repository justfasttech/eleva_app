import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/content_theme.dart';

final contentThemesProvider = StreamProvider<List<ContentTheme>>((ref) {
  return Supabase.instance.client
      .from('content_themes')
      .stream(primaryKey: ['id'])
      .order('name')
      .map((rows) => rows.map(ContentTheme.fromMap).toList());
});
