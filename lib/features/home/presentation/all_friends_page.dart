import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme.dart';
import '../../community/presentation/chat_screen.dart';
import '../../community/providers/friends_provider.dart';

class AllFriendsPage extends ConsumerWidget {
  const AllFriendsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(acceptedFriendsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Amigos'),
        centerTitle: true,
      ),
      body: friendsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: ElevaColors.gold),
        ),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (friends) {
          if (friends.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_add_rounded,
                    size: 48,
                    color: ElevaColors.gold.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Nenhum amigo adicionado ainda',
                    style: TextStyle(
                      fontSize: 15,
                      color: ElevaColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Adicione amigos na aba Comunidade',
                    style: TextStyle(
                      fontSize: 13,
                      color: ElevaColors.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 20,
              childAspectRatio: 0.7,
            ),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return _FriendGridItem(
                friendId: friend.id,
                name: friend.name,
                level: friend.treeLevel,
                faithLevel: friend.faithLevel,
              );
            },
          );
        },
      ),
    );
  }
}

class _FriendGridItem extends StatelessWidget {
  final String friendId;
  final String name;
  final int level;
  final int faithLevel;

  const _FriendGridItem({
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
          Expanded(
            child: Container(
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
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ElevaColors.textDark,
            ),
            overflow: TextOverflow.ellipsis,
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
