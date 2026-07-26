import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme.dart';
import '../../../auth/providers/user_profile_provider.dart';
import '../../../notifications/providers/notifications_provider.dart';
import '../../models/post.dart';
import '../../models/post_comment.dart';
import '../../providers/forum_provider.dart';
import '../user_profile_sheet.dart';

class ForumTab extends ConsumerStatefulWidget {
  const ForumTab({super.key});

  @override
  ConsumerState<ForumTab> createState() => _ForumTabState();
}

class _ForumTabState extends ConsumerState<ForumTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsProvider);
    final searchQuery = _searchQuery;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Pesquisar por título...',
              prefixIcon: const Icon(Icons.search, color: ElevaColors.gold),
              filled: true,
              fillColor: ElevaColors.offWhite,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            color: ElevaColors.offWhite,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showNewPostSheet(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded,
                        size: 20, color: ElevaColors.gold),
                    SizedBox(width: 12),
                    Text(
                      'Fazer uma pergunta...',
                      style: TextStyle(
                          fontSize: 14, color: ElevaColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: postsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: ElevaColors.gold),
            ),
            error: (e, _) => Center(
              child: Text('Erro: $e',
                  style: const TextStyle(color: ElevaColors.textMuted)),
            ),
            data: (posts) {
              final filtered = searchQuery.isEmpty
                  ? posts
                  : posts
                      .where((p) => p.title
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()))
                      .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    searchQuery.isEmpty
                        ? 'Nenhuma publicação ainda.\nSeja o primeiro a perguntar!'
                        : 'Nenhum resultado para "$searchQuery"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14, color: ElevaColors.textMuted),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) =>
                    _PostCard(post: filtered[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showNewPostSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _NewPostSheet(),
    );
  }
}

class _NewPostSheet extends ConsumerStatefulWidget {
  const _NewPostSheet();

  @override
  ConsumerState<_NewPostSheet> createState() => _NewPostSheetState();
}

class _NewPostSheetState extends ConsumerState<_NewPostSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha o título e a descrição'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final profile = ref.read(userProfileProvider).value;
      final authorName = profile?.name ?? 'Anônimo';

      await Supabase.instance.client.from('posts').insert({
        'user_id': user.id,
        'author_name': authorName,
        'title': title,
        'body': body,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Publicação criada!'),
            backgroundColor: ElevaColors.gold,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao publicar: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
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
            'Nova pergunta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ElevaColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration:
                const InputDecoration(hintText: 'Título da pergunta'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyController,
            decoration:
                const InputDecoration(hintText: 'Descreva sua dúvida...'),
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSaving ? null : _publish,
            child: _isSaving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: ElevaColors.white,
                    ),
                  )
                : const Text('Publicar'),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  final Post post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userLikes = ref.watch(userLikesProvider).value ?? {};
    final isLiked = userLikes.contains(post.id);
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ElevaColors.offWhite,
        borderRadius: BorderRadius.circular(16),
        border: post.isAdmin
            ? Border.all(
                color: ElevaColors.gold.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => showUserProfileSheet(
                    context, post.authorName, post.avatarLetter, post.userId),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: post.isAdmin
                      ? ElevaColors.gold
                      : ElevaColors.gold.withValues(alpha: 0.15),
                  child: Text(
                    post.avatarLetter,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: post.isAdmin ? Colors.white : ElevaColors.gold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => showUserProfileSheet(
                              context,
                              post.authorName,
                              post.avatarLetter,
                              post.userId),
                          child: Text(
                            post.authorName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ElevaColors.textDark,
                            ),
                          ),
                        ),
                        if (post.isAdmin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: ElevaColors.gold,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      post.timeAgo,
                      style: const TextStyle(
                          fontSize: 11, color: ElevaColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: ElevaColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            post.body,
            style: const TextStyle(
              fontSize: 13,
              color: ElevaColors.textMuted,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleLike(ref, currentUserId, isLiked),
                child: Row(
                  children: [
                    Icon(
                      isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 18,
                      color: isLiked
                          ? ElevaColors.gold
                          : ElevaColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likesCount}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isLiked
                            ? ElevaColors.gold
                            : ElevaColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => _showReplies(context, ref),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        size: 16, color: ElevaColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${post.commentsCount}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: ElevaColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike(WidgetRef ref, String userId, bool isLiked) async {
    try {
      if (isLiked) {
        await Supabase.instance.client
            .from('post_likes')
            .delete()
            .eq('post_id', post.id)
            .eq('user_id', userId);
      } else {
        await Supabase.instance.client.from('post_likes').insert({
          'post_id': post.id,
          'user_id': userId,
        });
      }
      ref.invalidate(userLikesProvider);
      ref.invalidate(postsProvider);
    } catch (_) {}
  }

  void _showReplies(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RepliesSheet(
        postId: post.id,
        title: post.title,
        postUserId: post.userId,
      ),
    );
  }
}

class _RepliesSheet extends ConsumerStatefulWidget {
  final String postId;
  final String title;
  final String postUserId;
  const _RepliesSheet({
    required this.postId,
    required this.title,
    required this.postUserId,
  });

  @override
  ConsumerState<_RepliesSheet> createState() => _RepliesSheetState();
}

class _RepliesSheetState extends ConsumerState<_RepliesSheet> {
  final _replyController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final profile = ref.read(userProfileProvider).value;
      final authorName = profile?.name ?? 'Anônimo';

      await Supabase.instance.client.from('post_comments').insert({
        'post_id': widget.postId,
        'user_id': user.id,
        'author_name': authorName,
        'content': content,
      });

      if (widget.postUserId != user.id) {
        await createUserNotification(
          targetUserId: widget.postUserId,
          title: 'Nova resposta',
          body: '$authorName respondeu sua pergunta: "${widget.title}"',
          type: 'forum_answer',
        );
      }

      _replyController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
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
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ElevaColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: commentsAsync.when(
                loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: ElevaColors.gold),
                ),
                error: (e, _) => Center(child: Text('Erro: $e')),
                data: (comments) {
                  if (comments.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhuma resposta ainda.\nSeja o primeiro!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14, color: ElevaColors.textMuted),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: comments.length,
                    itemBuilder: (context, i) =>
                        _ReplyItem(comment: comments[i]),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: const InputDecoration(
                        hintText: 'Escrever resposta...'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSending ? null : _sendReply,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ElevaColors.gold,
                          ),
                        )
                      : const Icon(Icons.send_rounded,
                          color: ElevaColors.gold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyItem extends StatelessWidget {
  final PostComment comment;
  const _ReplyItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: ElevaColors.gold.withValues(alpha: 0.15),
            child: Text(
              comment.avatarLetter,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ElevaColors.gold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ElevaColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.timeAgo,
                      style: const TextStyle(
                          fontSize: 11, color: ElevaColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ElevaColors.textDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
