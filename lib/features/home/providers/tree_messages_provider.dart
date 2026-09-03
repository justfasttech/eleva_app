import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/tree_message.dart';

final treeMessagesProvider = StreamProvider<List<TreeMessage>>((ref) {
  return Supabase.instance.client
      .from('tree_messages')
      .stream(primaryKey: ['id'])
      .order('level')
      .map((rows) => rows.map(TreeMessage.fromMap).toList());
});
