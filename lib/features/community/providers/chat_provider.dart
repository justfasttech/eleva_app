import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/conversation.dart';
import '../models/message.dart';

final conversationsProvider = StreamProvider<List<Conversation>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  return Supabase.instance.client
      .from('conversations')
      .stream(primaryKey: ['id'])
      .order('last_message_at', ascending: false)
      .asyncMap((rows) async {
    final myConvs = rows.where(
      (r) => r['user1_id'] == user.id || r['user2_id'] == user.id,
    );

    final conversations = <Conversation>[];
    for (final row in myConvs) {
      final otherId =
          row['user1_id'] == user.id ? row['user2_id'] : row['user1_id'];
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('name')
          .eq('id', otherId)
          .maybeSingle();
      final name = profile?['name'] as String? ?? '';
      conversations.add(Conversation.fromMap(row, user.id, name));
    }
    return conversations;
  });
});

final messagesProvider =
    StreamProvider.family<List<Message>, String>((ref, conversationId) {
  if (ref.watch(authStateProvider).value == null) return Stream.value([]);

  return Supabase.instance.client
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('conversation_id', conversationId)
      .order('created_at', ascending: true)
      .map((rows) => rows.map(Message.fromMap).toList());
});
