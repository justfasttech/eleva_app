import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme.dart';
import '../../providers/chat_provider.dart';
import '../chat_screen.dart';

class ChatTab extends ConsumerWidget {
  const ChatTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return conversationsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: ElevaColors.gold),
      ),
      error: (e, _) => Center(
        child: Text('Erro: $e',
            style: const TextStyle(color: ElevaColors.textMuted)),
      ),
      data: (conversations) {
        if (conversations.isEmpty) {
          return const Center(
            child: Text(
              'Nenhuma conversa ainda.\nInicie uma conversa pelo perfil de um usuário!',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 14, color: ElevaColors.textMuted),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: conversations.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: ElevaColors.textMuted.withValues(alpha: 0.1),
            indent: 62,
          ),
          itemBuilder: (context, i) {
            final conv = conversations[i];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  final currentUserId =
                      Supabase.instance.client.auth.currentUser!.id;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        conversationId: conv.id,
                        name: conv.otherUserName,
                        avatar: conv.avatarLetter,
                        otherUserId: conv.otherUserId(currentUserId),
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            ElevaColors.gold.withValues(alpha: 0.15),
                        child: const Icon(Icons.person,
                            size: 24, color: ElevaColors.gold),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    conv.otherUserName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: ElevaColors.textDark,
                                    ),
                                  ),
                                ),
                                Text(
                                  conv.timeLabel,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: ElevaColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              conv.lastMessageText ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: ElevaColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
