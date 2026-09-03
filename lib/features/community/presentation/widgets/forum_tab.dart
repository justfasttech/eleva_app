import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme.dart';
import '../../../auth/providers/user_profile_provider.dart';
import '../../../notifications/providers/notifications_provider.dart';
import '../../models/post.dart';
import '../../utils/media_upload.dart';
import '../../models/post_comment.dart';
import '../../providers/forum_provider.dart';
import '../../providers/themes_provider.dart';
import '../user_profile_sheet.dart';
import 'post_media.dart';

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
    final themesAsync = ref.watch(postThemesProvider);
    final searchQuery = _searchQuery;
    final themes = themesAsync.value ?? [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Pesquisar por título ou tema...',
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
        const SizedBox(height: 8),
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
                      'Nova publicação...',
                      style: TextStyle(
                          fontSize: 14, color: ElevaColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
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
              var filtered = posts;
              if (searchQuery.isNotEmpty) {
                final q = searchQuery.toLowerCase();
                filtered = posts.where((p) {
                  if (p.title.toLowerCase().contains(q)) return true;
                  if (p.themeId != null) {
                    final theme = themes.where((t) => t.id == p.themeId).firstOrNull;
                    if (theme != null && theme.name.toLowerCase().contains(q)) return true;
                  }
                  return false;
                }).toList();
              }

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    searchQuery.isEmpty
                        ? 'Nenhuma publicação ainda.\nSeja o primeiro!'
                        : 'Nenhum resultado encontrado',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14, color: ElevaColors.textMuted),
                  ),
                );
              }
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Container(
                      height: 8,
                      color: const Color(0xFFF0F0F0),
                    ),
                    itemBuilder: (context, i) =>
                        _PostCard(post: filtered[i]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showNewPostSheet(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final rootMessenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        bool isSaving = false;
        String? selectedThemeId;
        String? errorMessage;
        Uint8List? imageBytes;
        String? imageFileName;
        Uint8List? videoBytes;
        String? videoFileName;
        bool isQuestion = false;
        final themes = ref.read(postThemesProvider).value ?? [];

        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: EdgeInsets.fromLTRB(
              24, 12, 24,
              MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ElevaColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (errorMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, size: 18, color: Colors.red.shade400),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setSheetState(() => errorMessage = null),
                          child: Icon(Icons.close, size: 16, color: Colors.red.shade300),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Nova publicação',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ElevaColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (themes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedThemeId,
                      decoration: InputDecoration(
                        hintText: 'Selecione um tema',
                        prefixIcon: const Icon(Icons.label_outline_rounded, color: ElevaColors.gold),
                        filled: true,
                        fillColor: ElevaColors.offWhite,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: themes.map((t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(t.name),
                      )).toList(),
                      onChanged: (value) => setSheetState(() => selectedThemeId = value),
                    ),
                  ),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Título',
                    prefixIcon: const Icon(Icons.title_rounded, color: ElevaColors.gold),
                    filled: true,
                    fillColor: ElevaColors.offWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Escreva sua publicação...',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: ElevaColors.offWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  textAlignVertical: TextAlignVertical.top,
                  textCapitalization: TextCapitalization.sentences,
                ),
                CheckboxListTile(
                  value: isQuestion,
                  onChanged: (v) => setSheetState(() => isQuestion = v ?? false),
                  title: const Text('É uma pergunta?', style: TextStyle(fontSize: 14)),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: ElevaColors.gold,
                ),
                const SizedBox(height: 4),
                if (imageBytes == null && videoFileName == null)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(type: FileType.media);
                            if (result == null || result.files.isEmpty) return;
                            final file = result.files.first;
                            if (file.bytes == null) return;
                            final ext = file.extension?.toLowerCase() ?? '';
                            final isVideo = ['mp4', 'mov', 'avi', 'webm'].contains(ext);
                            setSheetState(() {
                              if (isVideo) {
                                videoBytes = file.bytes;
                                videoFileName = file.name;
                              } else {
                                imageBytes = file.bytes;
                                imageFileName = file.name;
                              }
                            });
                          },
                          icon: const Icon(Icons.attach_file_rounded, size: 18),
                          label: const Text('Arquivo'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ElevaColors.gold,
                            side: const BorderSide(color: ElevaColors.gold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      if (!kIsWeb) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 1920);
                              if (picked == null) return;
                              final bytes = await picked.readAsBytes();
                              setSheetState(() {
                                imageBytes = bytes;
                                imageFileName = picked.name;
                                videoBytes = null;
                                videoFileName = null;
                              });
                            },
                            icon: const Icon(Icons.camera_alt_rounded, size: 18),
                            label: const Text('Câmera'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ElevaColors.gold,
                              side: const BorderSide(color: ElevaColors.gold),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                if (imageBytes != null || videoFileName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: ElevaColors.offWhite,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          if (imageBytes != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.memory(imageBytes!, width: 40, height: 40, fit: BoxFit.cover),
                            )
                          else
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: ElevaColors.gold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.videocam_rounded, size: 20, color: ElevaColors.gold),
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              imageFileName ?? videoFileName ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: ElevaColors.textDark),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setSheetState(() {
                              imageBytes = null; imageFileName = null;
                              videoBytes = null; videoFileName = null;
                            }),
                            child: const Icon(Icons.close_rounded, size: 20, color: ElevaColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final title = titleController.text.trim();
                            final body = bodyController.text.trim();
                            if (selectedThemeId == null) {
                              setSheetState(() => errorMessage = 'Selecione um tema');
                              return;
                            }
                            if (title.isEmpty || body.isEmpty) {
                              setSheetState(() => errorMessage = 'Preencha o título e a descrição');
                              return;
                            }
                            setSheetState(() { isSaving = true; errorMessage = null; });
                            try {
                              final user = Supabase.instance.client.auth.currentUser!;
                              final profile = ref.read(userProfileProvider).value;
                              final authorName = profile?.name ?? 'Anônimo';

                              String? imageUrl;
                              String? videoUrl;
                              if (imageBytes != null) {
                                imageUrl = await CommunityMediaUploader.uploadImage(
                                  imageBytes!, imageFileName ?? 'image.jpg', user.id,
                                );
                              }
                              if (videoBytes != null) {
                                videoUrl = await CommunityMediaUploader.uploadVideo(
                                  videoBytes!, videoFileName ?? 'video.mp4', user.id,
                                );
                              }

                              await Supabase.instance.client.from('posts').insert({
                                'user_id': user.id,
                                'author_name': authorName,
                                'title': title,
                                'body': body,
                                'theme_id': selectedThemeId,
                                'is_question': isQuestion,
                                if (imageUrl != null) 'image_url': imageUrl,
                                if (videoUrl != null) 'video_url': videoUrl,
                              });
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                rootMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Publicação criada!'),
                                    backgroundColor: ElevaColors.gold,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                setSheetState(() => errorMessage = 'Erro ao publicar: $e');
                              }
                            } finally {
                              if (ctx.mounted) setSheetState(() => isSaving = false);
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ElevaColors.white,
                            ),
                          )
                        : const Text('Publicar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => showUserProfileSheet(
                      context, post.authorName, post.avatarLetter, post.userId),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: post.isAdmin
                        ? ElevaColors.gold
                        : ElevaColors.gold.withValues(alpha: 0.15),
                    child: Text(
                      post.avatarLetter,
                      style: TextStyle(
                        fontSize: 15,
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
                                fontSize: 14,
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
                      Row(
                        children: [
                          Text(
                            post.timeAgo,
                            style: const TextStyle(
                                fontSize: 12, color: ElevaColors.textMuted),
                          ),
                          if (post.themeId != null) ...[
                            const Text(' · ', style: TextStyle(color: ElevaColors.textMuted)),
                            _PostThemeChip(themeId: post.themeId!),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              post.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ElevaColors.textDark,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              post.body,
              style: const TextStyle(
                fontSize: 14,
                color: ElevaColors.textDark,
                height: 1.4,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (post.hasImage || post.hasVideo)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: PostMediaDisplay(
                imageUrl: post.imageUrl,
                videoUrl: post.videoUrl,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleLike(ref, currentUserId, isLiked),
                  child: Row(
                    children: [
                      Icon(
                        isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 20,
                        color: isLiked
                            ? ElevaColors.gold
                            : ElevaColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.likesCount}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isLiked
                              ? ElevaColors.gold
                              : ElevaColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () => _showReplies(context, ref),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded,
                          size: 18, color: ElevaColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${post.commentsCount}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: ElevaColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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


class _PostThemeChip extends ConsumerWidget {
  final String themeId;
  const _PostThemeChip({required this.themeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themesAsync = ref.watch(postThemesProvider);
    return themesAsync.when(
      data: (themes) {
        final theme = themes.where((t) => t.id == themeId).firstOrNull;
        if (theme == null) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: ElevaColors.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            theme.name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ElevaColors.gold,
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
