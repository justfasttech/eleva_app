import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme.dart';

final _forumPostsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return Supabase.instance.client
      .from('posts')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows);
});

final _postCommentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, postId) async {
  final res = await Supabase.instance.client
      .from('post_comments')
      .select()
      .eq('post_id', postId)
      .order('created_at');
  return List<Map<String, dynamic>>.from(res);
});

class AdminCommunityPage extends ConsumerStatefulWidget {
  const AdminCommunityPage({super.key});

  @override
  ConsumerState<AdminCommunityPage> createState() => _AdminCommunityPageState();
}

class _AdminCommunityPageState extends ConsumerState<AdminCommunityPage> {
  String _filter = 'Recentes';

  static const _filters = ['Recentes', 'Sem resposta', 'Respondidas'];

  bool _hasAdminReply(Map<String, dynamic> post) {
    final isAdmin = post['is_admin'] as bool? ?? false;
    if (isAdmin) return true;
    return post['admin_replied'] as bool? ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final postsAsync = ref.watch(_forumPostsProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text('Comunidade', style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface)),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Responda perguntas como Admin',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: _filters.map((f) {
                final isActive = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? cs.primary : cs.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(f, style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : cs.onSurfaceVariant)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: postsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (posts) {
                var filtered = posts;
                if (_filter == 'Sem resposta') {
                  filtered = posts.where((p) => !_hasAdminReply(p)).toList();
                } else if (_filter == 'Respondidas') {
                  filtered = posts.where((p) => _hasAdminReply(p)).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Text('Nenhum post encontrado',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final p = filtered[i];
                    return _PostCard(post: p);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  final Map<String, dynamic> post;

  const _PostCard({required this.post});

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays < 7) return 'há ${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final author = post['author_name'] as String? ?? 'Anônimo';
    final avatar = author.isNotEmpty ? author[0].toUpperCase() : '?';
    final title = post['title'] as String? ?? '';
    final body = post['body'] as String? ?? '';
    final likes = post['likes_count'] as int? ?? 0;
    final comments = post['comments_count'] as int? ?? 0;
    final isAdmin = post['is_admin'] as bool? ?? false;
    final adminReplied = post['admin_replied'] as bool? ?? false;
    final time = _timeAgo(post['created_at'] as String?);
    final postId = post['id'] as String;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: isAdmin
            ? Border.all(color: cs.primary.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: cs.primary.withValues(alpha: 0.15),
                child: Text(avatar, style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(author, style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
                    Text(time, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              if (isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 12, color: cs.primary),
                      const SizedBox(width: 4),
                      Text('Admin', style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600, color: cs.primary)),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: adminReplied
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    adminReplied ? 'Respondida' : 'Pendente',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: adminReplied ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 4),
          Text(body, style: TextStyle(
              fontSize: 13, color: cs.onSurfaceVariant, height: 1.3),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.favorite_rounded, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('$likes', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline_rounded, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('$comments', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCommentsSheet(context, ref, postId, title, author),
                    icon: const Icon(Icons.visibility_rounded, size: 14),
                    label: const Text('Ver respostas'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      side: BorderSide(color: cs.primary.withValues(alpha: 0.5)),
                      foregroundColor: cs.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!adminReplied)
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: () => _showReplySheet(context, ref, postId, title, author),
                      icon: const Icon(Icons.reply_rounded, size: 14),
                      label: const Text('Responder'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                )
              else ...[
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditReplySheet(context, ref, postId),
                      icon: const Icon(Icons.edit_rounded, size: 14),
                      label: const Text('Editar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        foregroundColor: cs.primary,
                        side: BorderSide(color: cs.primary.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDeleteReply(context, ref, postId),
                      icon: const Icon(Icons.delete_outline_rounded, size: 14),
                      label: const Text('Remover'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showCommentsSheet(BuildContext context, WidgetRef ref, String postId, String title, String author) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, _) {
                final commentsAsync = ref.watch(_postCommentsProvider(postId));

                return Column(
                  children: [
                    const SizedBox(height: 8),
                    Center(child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2)),
                    )),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Icon(Icons.forum_rounded, size: 20, color: cs.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Respostas de "$title"',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: commentsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Erro: $e')),
                        data: (comments) {
                          if (comments.isEmpty) {
                            return Center(
                              child: Text('Nenhuma resposta ainda',
                                style: TextStyle(color: cs.onSurfaceVariant)),
                            );
                          }
                          return ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            itemCount: comments.length,
                            itemBuilder: (context, i) {
                              final c = comments[i];
                              final cAuthor = c['author_name'] as String? ?? 'Anônimo';
                              final cContent = c['content'] as String? ?? '';
                              final cAvatar = cAuthor.isNotEmpty ? cAuthor[0].toUpperCase() : '?';
                              final cTime = c['created_at'] as String?;
                              final dt = cTime != null ? DateTime.tryParse(cTime) : null;
                              final timeLabel = dt != null
                                  ? '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                                  : '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cs.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: cs.onSurfaceVariant.withValues(alpha: 0.1)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: cs.primary.withValues(alpha: 0.15),
                                      child: Text(cAvatar, style: TextStyle(
                                          fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(cAuthor, style: TextStyle(
                                                  fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
                                              const SizedBox(width: 8),
                                              Text(timeLabel, style: TextStyle(
                                                  fontSize: 11, color: cs.onSurfaceVariant)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(cContent, style: TextStyle(
                                              fontSize: 13, color: cs.onSurface, height: 1.3)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showReplySheet(BuildContext context, WidgetRef ref, String postId, String title, String author) {
    final cs = Theme.of(context).colorScheme;
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.primary, borderRadius: BorderRadius.circular(6)),
                child: const Text('ADMIN', style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Respondendo a $author', style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: TextStyle(color: cs.onSurface),
              decoration: const InputDecoration(hintText: 'Escreva sua resposta como Admin...'),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;

                  try {
                    final userId = Supabase.instance.client.auth.currentUser!.id;
                    final profile = await Supabase.instance.client
                        .from('profiles')
                        .select('name')
                        .eq('id', userId)
                        .single();
                    final adminName = profile['name'] as String? ?? 'Admin';

                    await Supabase.instance.client.from('post_comments').insert({
                      'post_id': postId,
                      'user_id': userId,
                      'author_name': adminName,
                      'content': text,
                    });

                    await Supabase.instance.client.rpc(
                      'mark_post_admin_replied',
                      params: {'p_post_id': postId},
                    );

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Resposta enviada!'),
                          backgroundColor: ElevaColors.gold,
                        ),
                      );
                    }
                    ref.invalidate(_forumPostsProvider);
                    ref.invalidate(_postCommentsProvider(postId));
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: const Text('Enviar resposta'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditReplySheet(BuildContext context, WidgetRef ref, String postId) async {
    final cs = Theme.of(context).colorScheme;
    final userId = Supabase.instance.client.auth.currentUser!.id;

    final comments = await Supabase.instance.client
        .from('post_comments')
        .select()
        .eq('post_id', postId)
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1);

    if (comments.isEmpty) return;
    final comment = comments[0];
    final commentId = comment['id'] as String;
    final controller = TextEditingController(text: comment['content'] as String? ?? '');

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            const SizedBox(height: 20),
            Text('Editar resposta', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: TextStyle(color: cs.onSurface),
              decoration: const InputDecoration(hintText: 'Sua resposta...'),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;
                  try {
                    await Supabase.instance.client
                        .from('post_comments')
                        .update({'content': text})
                        .eq('id', commentId);

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Resposta atualizada!'),
                          backgroundColor: ElevaColors.gold,
                        ),
                      );
                    }
                    ref.invalidate(_forumPostsProvider);
                    ref.invalidate(_postCommentsProvider(postId));
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: const Text('Salvar alterações'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteReply(BuildContext context, WidgetRef ref, String postId) {
    final cs = Theme.of(context).colorScheme;
    final userId = Supabase.instance.client.auth.currentUser!.id;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('Remover resposta?', style: TextStyle(color: cs.onSurface)),
        content: Text('Sua resposta será removida deste post.',
            style: TextStyle(color: cs.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client
                    .from('post_comments')
                    .delete()
                    .eq('post_id', postId)
                    .eq('user_id', userId);

                await Supabase.instance.client.rpc(
                  'unmark_post_admin_replied',
                  params: {'p_post_id': postId},
                );

                ref.invalidate(_forumPostsProvider);
                ref.invalidate(_postCommentsProvider(postId));

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Resposta removida'),
                      backgroundColor: ElevaColors.gold,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
