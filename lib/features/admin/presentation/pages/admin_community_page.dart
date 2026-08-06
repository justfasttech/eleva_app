import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme.dart';
import '../../../community/presentation/widgets/post_media.dart';
import '../../../community/providers/groups_provider.dart';

// --- Providers ---

final _questionPostsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return Supabase.instance.client
      .from('posts')
      .stream(primaryKey: ['id'])
      .eq('is_question', true)
      .order('created_at', ascending: false)
      .map((rows) => rows);
});

final _allPostsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return Supabase.instance.client
      .from('posts')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows.where((r) => r['is_question'] != true).toList());
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

final _groupPostCommentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, postId) async {
  final res = await Supabase.instance.client
      .from('group_post_comments')
      .select()
      .eq('post_id', postId)
      .order('created_at');
  return List<Map<String, dynamic>>.from(res);
});

final _groupNamesProvider = FutureProvider<Map<String, String>>((ref) async {
  final res = await Supabase.instance.client.from('groups').select('id, name');
  final map = <String, String>{};
  for (final row in res) {
    map[row['id'] as String] = row['name'] as String? ?? '';
  }
  return map;
});

// --- Main Page ---

class AdminCommunityPage extends ConsumerStatefulWidget {
  const AdminCommunityPage({super.key});

  @override
  ConsumerState<AdminCommunityPage> createState() => _AdminCommunityPageState();
}

class _AdminCommunityPageState extends ConsumerState<AdminCommunityPage>
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
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text('Comunidade',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Gerencie posts, perguntas e grupos',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurfaceVariant,
            indicatorColor: cs.primary,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Perguntas'),
              Tab(text: 'Comunidade'),
              Tab(text: 'Grupos'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _QuestionsTab(),
                _CommunityTab(),
                _GroupsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================
// TAB 1 — Perguntas (is_question = true)
// =============================================

class _QuestionsTab extends ConsumerStatefulWidget {
  const _QuestionsTab();

  @override
  ConsumerState<_QuestionsTab> createState() => _QuestionsTabState();
}

class _QuestionsTabState extends ConsumerState<_QuestionsTab> {
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
    final postsAsync = ref.watch(_questionPostsProvider);

    return Column(
      children: [
        const SizedBox(height: 12),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? cs.primary : cs.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(f,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? Colors.white
                                : cs.onSurfaceVariant)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
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
                  child: Text('Nenhuma pergunta encontrada',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _QuestionCard(post: filtered[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

// =============================================
// TAB 2 — Comunidade (todos os posts)
// =============================================

class _CommunityTab extends ConsumerWidget {
  const _CommunityTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final postsAsync = ref.watch(_allPostsProvider);

    return postsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Text('Nenhum post encontrado',
                style: TextStyle(color: cs.onSurfaceVariant)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _GeneralPostCard(
            post: posts[i],
            tableName: 'posts',
            commentsTable: 'post_comments',
            commentsProvider: _postCommentsProvider.call,
            onDeleted: () {
              ref.invalidate(_allPostsProvider);
              ref.invalidate(_questionPostsProvider);
            },
          ),
        );
      },
    );
  }
}

// =============================================
// TAB 3 — Grupos (todos os posts de grupo)
// =============================================

class _GroupsTab extends ConsumerStatefulWidget {
  const _GroupsTab();

  @override
  ConsumerState<_GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends ConsumerState<_GroupsTab> {
  String? _selectedGroupId;
  String? _selectedGroupName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final groupNamesAsync = ref.watch(_groupNamesProvider);

    if (_selectedGroupId == null) {
      return groupNamesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (groupNames) {
          if (groupNames.isEmpty) {
            return Center(
              child: Text('Nenhum grupo encontrado',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            );
          }

          final postCounts = <String, int>{};
          for (final gId in groupNames.keys) {
            final postsVal = ref.watch(groupPostsProvider(gId)).value;
            postCounts[gId] = postsVal?.length ?? 0;
          }

          final entries = groupNames.entries.toList();

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final groupId = entries[i].key;
              final groupName = entries[i].value;
              final postCount = postCounts[groupId] ?? 0;

              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() {
                  _selectedGroupId = groupId;
                  _selectedGroupName = groupName;
                }),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: cs.primary.withValues(alpha: 0.15),
                        child: Icon(Icons.group_rounded,
                            size: 20, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(groupName,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface)),
                            const SizedBox(height: 2),
                            Text(
                                postCount == 1
                                    ? '1 post'
                                    : '$postCount posts',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: cs.onSurfaceVariant),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }

    final postsAsync = ref.watch(groupPostsProvider(_selectedGroupId!));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 24, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() {
                  _selectedGroupId = null;
                  _selectedGroupName = null;
                }),
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                tooltip: 'Voltar aos grupos',
              ),
              const SizedBox(width: 4),
              Icon(Icons.group_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_selectedGroupName ?? 'Grupo',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: postsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (posts) {
              if (posts.isEmpty) {
                return Center(
                  child: Text('Nenhum post neste grupo',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                itemCount: posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final gp = posts[i];
                  final post = <String, dynamic>{
                    'id': gp.id,
                    'group_id': gp.groupId,
                    'user_id': gp.userId,
                    'author_name': gp.authorName,
                    'title': gp.title,
                    'content': gp.content,
                    'likes_count': gp.likesCount,
                    'comments_count': gp.commentsCount,
                    'created_at': gp.createdAt.toIso8601String(),
                    'image_url': gp.imageUrl,
                    'video_url': gp.videoUrl,
                    'is_question': gp.isQuestion,
                  };
                  return _GeneralPostCard(
                    post: post,
                    tableName: 'group_posts',
                    commentsTable: 'group_post_comments',
                    commentsProvider: _groupPostCommentsProvider.call,
                    onDeleted: () => ref.invalidate(
                        groupPostsProvider(_selectedGroupId!)),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// =============================================
// Widgets de Card
// =============================================

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

// --- Card de Pergunta (tab 1) ---

class _QuestionCard extends ConsumerWidget {
  final Map<String, dynamic> post;
  const _QuestionCard({required this.post});

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
    final imageUrl = post['image_url'] as String?;
    final videoUrl = post['video_url'] as String?;

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
                child: Text(avatar,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.primary)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(author,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface)),
                    Text(time,
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              if (isAdmin)
                _badge(cs.primary.withValues(alpha: 0.15), cs.primary, 'Admin',
                    icon: Icons.check_circle_rounded)
              else
                _badge(
                  adminReplied
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  adminReplied ? Colors.green : Colors.orange,
                  adminReplied ? 'Respondida' : 'Pendente',
                ),
              const SizedBox(width: 4),
              _deletePostButton(context, ref, postId, 'posts', () {
                ref.invalidate(_questionPostsProvider);
                ref.invalidate(_allPostsProvider);
              }),
            ],
          ),
          const SizedBox(height: 10),
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const SizedBox(height: 4),
          Text(body,
              style: TextStyle(
                  fontSize: 13, color: cs.onSurfaceVariant, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (imageUrl != null || videoUrl != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: PostMediaDisplay(
                  imageUrl: imageUrl, videoUrl: videoUrl, autoplay: false),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.favorite_rounded, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('$likes',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('$comments',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCommentsSheet(
                        context, ref, postId, title, 'post_comments',
                        _postCommentsProvider.call),
                    icon: const Icon(Icons.visibility_rounded, size: 14),
                    label: const Text('Ver respostas'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600),
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
                      onPressed: () =>
                          _showReplySheet(context, ref, postId, title, author),
                      icon: const Icon(Icons.reply_rounded, size: 14),
                      label: const Text('Responder'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showEditReplySheet(context, ref, postId),
                      icon: const Icon(Icons.edit_rounded, size: 14),
                      label: const Text('Editar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600),
                        foregroundColor: cs.primary,
                        side: BorderSide(
                            color: cs.primary.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReplySheet(BuildContext context, WidgetRef ref, String postId,
      String title, String author) {
    final cs = Theme.of(context).colorScheme;
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: cs.primary, borderRadius: BorderRadius.circular(6)),
                child: const Text('ADMIN',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Respondendo a $author',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: TextStyle(color: cs.onSurface),
              decoration: const InputDecoration(
                  hintText: 'Escreva sua resposta como Admin...'),
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
                    final userId =
                        Supabase.instance.client.auth.currentUser!.id;
                    final profile = await Supabase.instance.client
                        .from('profiles')
                        .select('name')
                        .eq('id', userId)
                        .single();
                    final adminName = profile['name'] as String? ?? 'Admin';

                    await Supabase.instance.client
                        .from('post_comments')
                        .insert({
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
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text('Resposta enviada!'),
                          backgroundColor: ElevaColors.gold));
                    }
                    ref.invalidate(_questionPostsProvider);
                    ref.invalidate(_allPostsProvider);
                    ref.invalidate(_postCommentsProvider(postId));
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: Text('Erro: $e'),
                          backgroundColor: Colors.red));
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

  void _showEditReplySheet(
      BuildContext context, WidgetRef ref, String postId) async {
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
    final controller =
        TextEditingController(text: comment['content'] as String? ?? '');

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 20),
            Text('Editar resposta',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
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
                        .update({'content': text}).eq('id', commentId);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text('Resposta atualizada!'),
                          backgroundColor: ElevaColors.gold));
                    }
                    ref.invalidate(_questionPostsProvider);
                    ref.invalidate(_allPostsProvider);
                    ref.invalidate(_postCommentsProvider(postId));
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: Text('Erro: $e'),
                          backgroundColor: Colors.red));
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
}

// --- Card genérico (tabs 2 e 3) ---

class _GeneralPostCard extends ConsumerWidget {
  final Map<String, dynamic> post;
  final String tableName;
  final String commentsTable;
  final FutureProvider<List<Map<String, dynamic>>> Function(String)
      commentsProvider;
  final String? groupName;
  final VoidCallback onDeleted;

  const _GeneralPostCard({
    required this.post,
    required this.tableName,
    required this.commentsTable,
    required this.commentsProvider,
    required this.onDeleted,
    this.groupName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final author = post['author_name'] as String? ?? 'Anônimo';
    final avatar = author.isNotEmpty ? author[0].toUpperCase() : '?';
    final title = post['title'] as String? ?? '';
    final body = (post['body'] as String? ?? post['content'] as String? ?? '');
    final likes = post['likes_count'] as int? ?? 0;
    final comments = post['comments_count'] as int? ?? 0;
    final time = _timeAgo(post['created_at'] as String?);
    final postId = post['id'] as String;
    final imageUrl = post['image_url'] as String?;
    final videoUrl = post['video_url'] as String?;
    final isQuestion = post['is_question'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: cs.primary.withValues(alpha: 0.15),
                child: Text(avatar,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.primary)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(author,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface)),
                    Row(
                      children: [
                        Text(time,
                            style: TextStyle(
                                fontSize: 11, color: cs.onSurfaceVariant)),
                        if (groupName != null) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.group_rounded,
                              size: 11, color: cs.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(groupName!,
                                style: TextStyle(
                                    fontSize: 11, color: cs.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isQuestion)
                _badge(Colors.blue.withValues(alpha: 0.15), Colors.blue,
                    'Pergunta',
                    icon: Icons.help_outline_rounded),
              const SizedBox(width: 4),
              _deletePostButton(context, ref, postId, tableName, onDeleted),
            ],
          ),
          const SizedBox(height: 10),
          if (title.isNotEmpty)
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
          if (title.isNotEmpty) const SizedBox(height: 4),
          Text(body,
              style: TextStyle(
                  fontSize: 13, color: cs.onSurfaceVariant, height: 1.3),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
          if (imageUrl != null || videoUrl != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: PostMediaDisplay(
                  imageUrl: imageUrl, videoUrl: videoUrl, autoplay: false),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.favorite_rounded, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('$likes',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('$comments',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              const Spacer(),
              SizedBox(
                height: 30,
                child: OutlinedButton.icon(
                  onPressed: () => _showCommentsSheet(context, ref, postId,
                      title, commentsTable, commentsProvider),
                  icon: const Icon(Icons.forum_rounded, size: 13),
                  label: const Text('Comentários'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    textStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                    side:
                        BorderSide(color: cs.primary.withValues(alpha: 0.5)),
                    foregroundColor: cs.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================
// Funções compartilhadas
// =============================================

Widget _badge(Color bg, Color fg, String text, {IconData? icon}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
        ],
        Text(text,
            style:
                TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
      ],
    ),
  );
}

Widget _deletePostButton(BuildContext context, WidgetRef ref, String postId,
    String tableName, VoidCallback onDeleted) {
  return IconButton(
    onPressed: () =>
        _confirmDeletePost(context, ref, postId, tableName, onDeleted),
    icon: const Icon(Icons.delete_outline_rounded, size: 18),
    color: Colors.red.withValues(alpha: 0.7),
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    tooltip: 'Excluir post',
  );
}

void _confirmDeletePost(BuildContext context, WidgetRef ref, String postId,
    String tableName, VoidCallback onDeleted) {
  final cs = Theme.of(context).colorScheme;

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: cs.surface,
      title: Text('Excluir post?', style: TextStyle(color: cs.onSurface)),
      content: Text(
          'O post e seus comentários serão removidos permanentemente.',
          style: TextStyle(color: cs.onSurfaceVariant)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child:
              Text('Cancelar', style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await Supabase.instance.client
                  .from(tableName)
                  .delete()
                  .eq('id', postId);
              onDeleted();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Post excluído'),
                    backgroundColor: ElevaColors.gold));
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Erro: $e'), backgroundColor: Colors.red));
              }
            }
          },
          child: const Text('Excluir', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

void _showCommentsSheet(
  BuildContext context,
  WidgetRef ref,
  String postId,
  String title,
  String commentsTable,
  FutureProvider<List<Map<String, dynamic>>> Function(String) commentsProvider,
) {
  final cs = Theme.of(context).colorScheme;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: cs.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          return Consumer(
            builder: (context, ref, _) {
              final commentsAsync = ref.watch(commentsProvider(postId));

              return Column(
                children: [
                  const SizedBox(height: 8),
                  Center(
                      child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2)),
                  )),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Icon(Icons.forum_rounded,
                            size: 20, color: cs.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title.isNotEmpty
                                ? 'Comentários de "$title"'
                                : 'Comentários',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: commentsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Erro: $e')),
                      data: (commentsList) {
                        if (commentsList.isEmpty) {
                          return Center(
                            child: Text('Nenhum comentário ainda',
                                style:
                                    TextStyle(color: cs.onSurfaceVariant)),
                          );
                        }
                        return ListView.builder(
                          controller: scrollController,
                          padding:
                              const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          itemCount: commentsList.length,
                          itemBuilder: (context, i) {
                            final c = commentsList[i];
                            return _CommentTile(
                              comment: c,
                              commentsTable: commentsTable,
                              onDeleted: () =>
                                  ref.invalidate(commentsProvider(postId)),
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

// --- Tile de comentário com exclusão ---

class _CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;
  final String commentsTable;
  final VoidCallback onDeleted;

  const _CommentTile({
    required this.comment,
    required this.commentsTable,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final author = comment['author_name'] as String? ?? 'Anônimo';
    final content = comment['content'] as String? ?? '';
    final avatar = author.isNotEmpty ? author[0].toUpperCase() : '?';
    final cTime = comment['created_at'] as String?;
    final dt = cTime != null ? DateTime.tryParse(cTime) : null;
    final timeLabel = dt != null
        ? '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
        : '';
    final commentId = comment['id'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: cs.onSurfaceVariant.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: cs.primary.withValues(alpha: 0.15),
            child: Text(avatar,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(author,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface)),
                    const SizedBox(width: 8),
                    Text(timeLabel,
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(content,
                    style: TextStyle(
                        fontSize: 13, color: cs.onSurface, height: 1.3)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDeleteComment(context, commentId),
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            color: Colors.red.withValues(alpha: 0.6),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: 'Excluir comentário',
          ),
        ],
      ),
    );
  }

  void _confirmDeleteComment(BuildContext context, String commentId) {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('Excluir comentário?',
            style: TextStyle(color: cs.onSurface)),
        content: Text('O comentário será removido permanentemente.',
            style: TextStyle(color: cs.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client
                    .from(commentsTable)
                    .delete()
                    .eq('id', commentId);
                onDeleted();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Comentário excluído'),
                      backgroundColor: ElevaColors.gold));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Erro: $e'),
                      backgroundColor: Colors.red));
                }
              }
            },
            child:
                const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
