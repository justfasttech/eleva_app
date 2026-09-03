import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_profile_provider.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../providers/friends_provider.dart';
import 'chat_screen.dart';

void showUserProfileSheet(
  BuildContext context,
  String name,
  String avatar,
  String userId,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _UserProfileSheet(
      name: name,
      avatar: avatar,
      userId: userId,
    ),
  );
}

class _UserProfileSheet extends ConsumerStatefulWidget {
  final String name;
  final String avatar;
  final String userId;

  const _UserProfileSheet({
    required this.name,
    required this.avatar,
    required this.userId,
  });

  @override
  ConsumerState<_UserProfileSheet> createState() => _UserProfileSheetState();
}

class _UserProfileSheetState extends ConsumerState<_UserProfileSheet> {
  bool _isSendingRequest = false;
  bool _isStartingChat = false;

  Future<void> _sendFriendRequest() async {
    setState(() => _isSendingRequest = true);
    try {
      final currentUser = Supabase.instance.client.auth.currentUser!;
      final profile = ref.read(userProfileProvider).value;
      final myName = profile?.name ?? '';

      await Supabase.instance.client.from('friend_requests').insert({
        'from_user_id': currentUser.id,
        'to_user_id': widget.userId,
        'from_user_name': myName,
      });

      await createUserNotification(
        targetUserId: widget.userId,
        title: 'Novo pedido de amizade',
        body: '$myName quer ser seu amigo!',
        type: 'friend_request',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido de amizade enviado!'),
            backgroundColor: ElevaColors.gold,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar pedido: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingRequest = false);
    }
  }

  Future<void> _startChat() async {
    setState(() => _isStartingChat = true);
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser!.id;
      final ids = [currentUserId, widget.userId]..sort();

      final existing = await Supabase.instance.client
          .from('conversations')
          .select('id')
          .eq('user1_id', ids[0])
          .eq('user2_id', ids[1])
          .maybeSingle();

      String conversationId;
      if (existing != null) {
        conversationId = existing['id'] as String;
      } else {
        final result = await Supabase.instance.client
            .from('conversations')
            .insert({
              'user1_id': ids[0],
              'user2_id': ids[1],
            })
            .select('id')
            .single();
        conversationId = result['id'] as String;
      }

      if (mounted) {
        Navigator.pop(context);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: conversationId,
              name: widget.name,
              avatar: widget.avatar,
              otherUserId: widget.userId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao iniciar conversa: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;
    final isMe = currentUser?.id == widget.userId;
    final sentRequests = ref.watch(sentFriendRequestsProvider).value ?? {};
    final alreadySent = sentRequests.contains(widget.userId);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ElevaColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 36,
            backgroundColor: ElevaColors.gold.withValues(alpha: 0.15),
            child: Text(
              widget.avatar,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: ElevaColors.gold,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ElevaColors.textDark,
            ),
          ),
          const SizedBox(height: 24),
          if (!isMe)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: alreadySent || _isSendingRequest
                        ? null
                        : _sendFriendRequest,
                    icon: _isSendingRequest
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ElevaColors.white,
                            ),
                          )
                        : Icon(
                            alreadySent
                                ? Icons.check_rounded
                                : Icons.person_add_rounded,
                            size: 18,
                          ),
                    label: Text(alreadySent ? 'Solicitado' : 'Adicionar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isStartingChat ? null : _startChat,
                    icon: _isStartingChat
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ElevaColors.gold,
                            ),
                          )
                        : const Icon(Icons.chat_rounded, size: 18),
                    label: const Text('Mensagem'),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
