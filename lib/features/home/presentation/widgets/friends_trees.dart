import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme.dart';
import '../../../community/presentation/chat_screen.dart';
import '../../../community/providers/friends_provider.dart';

class FriendsTrees extends ConsumerWidget {
  const FriendsTrees({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(acceptedFriendsProvider);

    return friendsAsync.when(
      loading: () => const SizedBox(
        height: 130,
        child: Center(
          child: CircularProgressIndicator(color: ElevaColors.gold),
        ),
      ),
      error: (_, __) => const SizedBox(
        height: 130,
        child: Center(
          child: Text(
            'Erro ao carregar amigos',
            style: TextStyle(color: ElevaColors.textMuted, fontSize: 13),
          ),
        ),
      ),
      data: (friends) {
        if (friends.isEmpty) {
          return SizedBox(
            height: 130,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_add_rounded,
                    size: 36,
                    color: ElevaColors.gold.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Adicione amigos na aba Comunidade',
                    style: TextStyle(
                      fontSize: 13,
                      color: ElevaColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: friends.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final friend = friends[index];
              return _FriendTreeCard(
                friendId: friend.id,
                name: friend.name,
                level: friend.treeLevel,
                faithLevel: friend.faithLevel,
              );
            },
          ),
        );
      },
    );
  }
}

class _FriendTreeCard extends StatelessWidget {
  final String friendId;
  final String name;
  final int level;
  final int faithLevel;

  const _FriendTreeCard({
    required this.friendId,
    required this.name,
    required this.level,
    required this.faithLevel,
  });

  Future<void> _openChat(BuildContext context) async {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final ids = [currentUserId, friendId]..sort();

    try {
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

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: conversationId,
              name: name,
              avatar: '',
              otherUserId: friendId,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir chat: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openChat(context),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: ElevaColors.offWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ElevaColors.goldLight.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/trees/$level.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.park_rounded,
                    size: 36,
                    color: ElevaColors.gold.withValues(alpha: 0.4),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ElevaColors.textDark,
            ),
          ),
          Text(
            '$faithLevel%',
            style: const TextStyle(
              fontSize: 11,
              color: ElevaColors.gold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
