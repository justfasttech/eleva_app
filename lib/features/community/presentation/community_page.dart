import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../models/friend_request.dart';
import '../providers/friends_provider.dart';
import 'widgets/chat_tab.dart';
import 'widgets/forum_tab.dart';
import 'widgets/groups_tab.dart';

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingRequests =
        ref.watch(pendingFriendRequestsProvider).value ?? [];
    final count = pendingRequests.length;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Comunidade',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: ElevaColors.textDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _showFriendRequests(context),
                  icon: Badge(
                    isLabelVisible: count > 0,
                    label: Text('$count',
                        style: const TextStyle(fontSize: 10)),
                    backgroundColor: ElevaColors.gold,
                    child: const Icon(Icons.person_add_rounded,
                        color: ElevaColors.textDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: ElevaColors.offWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: ElevaColors.textMuted,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
                indicator: BoxDecoration(
                  color: ElevaColors.gold,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: 'Fórum'),
                  Tab(text: 'Grupos'),
                  Tab(text: 'Chat'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                ForumTab(),
                GroupsTab(),
                ChatTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFriendRequests(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _FriendRequestsSheet(),
    );
  }
}

class _FriendRequestsSheet extends ConsumerWidget {
  const _FriendRequestsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingFriendRequestsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 20),
          const Text(
            'Pedidos de amizade',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ElevaColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          requestsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: ElevaColors.gold),
              ),
            ),
            error: (e, _) => Text('Erro: $e'),
            data: (requests) {
              if (requests.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Nenhum pedido pendente',
                      style: TextStyle(
                        fontSize: 14,
                        color: ElevaColors.textMuted,
                      ),
                    ),
                  ),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: requests
                    .map((req) => _FriendRequestTile(request: req))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _FriendRequestTile extends ConsumerStatefulWidget {
  final FriendRequest request;
  const _FriendRequestTile({required this.request});

  @override
  ConsumerState<_FriendRequestTile> createState() => _FriendRequestTileState();
}

class _FriendRequestTileState extends ConsumerState<_FriendRequestTile> {
  bool _isLoading = false;

  Future<void> _respond(String status) async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('friend_requests')
          .update({'status': status}).eq('id', widget.request.id);

      if (status == 'accepted') {
        ref.invalidate(acceptedFriendsProvider);

        final myName = ref.read(authStateProvider).value?.userMetadata?['name'] as String? ?? '';
        await createUserNotification(
          targetUserId: widget.request.fromUserId,
          title: 'Pedido aceito!',
          body: '$myName aceitou seu pedido de amizade.',
          type: 'friend_accepted',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'accepted'
                ? 'Pedido aceito!'
                : 'Pedido recusado'),
            backgroundColor:
                status == 'accepted' ? ElevaColors.gold : ElevaColors.textMuted,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: ElevaColors.gold.withValues(alpha: 0.15),
            child: Text(
              widget.request.avatarLetter,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: ElevaColors.gold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.request.fromUserName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: ElevaColors.textDark,
              ),
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ElevaColors.gold,
              ),
            )
          else ...[
            TextButton(
              onPressed: () => _respond('rejected'),
              child: const Text(
                'Recusar',
                style: TextStyle(color: ElevaColors.textMuted, fontSize: 13),
              ),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: () => _respond('accepted'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                textStyle: const TextStyle(fontSize: 13),
              ),
              child: const Text('Aceitar'),
            ),
          ],
        ],
      ),
    );
  }
}
