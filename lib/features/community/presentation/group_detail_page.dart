import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme.dart';
import '../../auth/providers/user_profile_provider.dart';
import '../models/community_group.dart';
import '../models/group_join_request.dart';
import '../models/group_post.dart';
import '../models/group_post_comment.dart';
import '../providers/groups_provider.dart';
import '../utils/media_upload.dart';
import 'widgets/post_media.dart';

class GroupDetailPage extends ConsumerStatefulWidget {
  final CommunityGroup group;
  final String creatorName;

  const GroupDetailPage({
    super.key,
    required this.group,
    required this.creatorName,
  });

  @override
  ConsumerState<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends ConsumerState<GroupDetailPage> {
  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser!.id;

  bool get _isCreator => widget.group.creatorId == _currentUserId;

  Future<void> _requestJoin(String message) async {
    final profile = ref.read(userProfileProvider).value;
    final name = profile?.name ?? '';

    try {
      await requestToJoinGroup(
        groupId: widget.group.id,
        userId: _currentUserId,
        userName: name,
        groupCreatorId: widget.group.creatorId,
        groupName: widget.group.name,
        message: message,
      );

      ref.invalidate(userJoinRequestsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitação enviada!'),
            backgroundColor: ElevaColors.gold,
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
    }
  }

  Future<void> _confirmDeleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir grupo'),
        content: const Text(
          'Tem certeza que deseja excluir este grupo? Todos os posts, membros e solicitações serão removidos. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await deleteGroup(widget.group.id);
      ref.invalidate(groupsProvider);
      ref.invalidate(userOwnsGroupProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberships =
        ref.watch(userGroupMembershipsProvider).value ?? {};
    final isMember = memberships.contains(widget.group.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        centerTitle: true,
        actions: [
          if (_isCreator) ...[
            IconButton(
              onPressed: () => _showJoinRequests(context),
              icon: _buildRequestsBadge(),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') _confirmDeleteGroup();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Excluir grupo',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          _GroupHeader(
            group: widget.group,
            creatorName: widget.creatorName,
            isMember: isMember,
            isCreator: _isCreator,
          ),
          if (!isMember)
            _JoinSection(
              onRequestJoin: (String msg) => _requestJoin(msg),
              groupId: widget.group.id,
            )
          else
            Expanded(
              child: _PostsSection(
                groupId: widget.group.id,
                isCreator: _isCreator,
                currentUserId: _currentUserId,
              ),
            ),
        ],
      ),
      floatingActionButton: isMember
          ? FloatingActionButton(
              onPressed: () => _showNewPostSheet(context),
              backgroundColor: ElevaColors.gold,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildRequestsBadge() {
    final requestsAsync =
        ref.watch(groupJoinRequestsProvider(widget.group.id));
    final count = requestsAsync.value?.length ?? 0;

    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count', style: const TextStyle(fontSize: 10)),
      backgroundColor: ElevaColors.gold,
      child: const Icon(Icons.group_add_rounded),
    );
  }

  void _showJoinRequests(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _JoinRequestsSheet(groupId: widget.group.id),
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
        String? errorMessage;
        Uint8List? imageBytes;
        String? imageFileName;
        Uint8List? videoBytes;
        String? videoFileName;

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
                const SizedBox(height: 8),
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

                              await createGroupPost(
                                groupId: widget.group.id,
                                userId: user.id,
                                authorName: authorName,
                                title: title,
                                content: body,
                                imageUrl: imageUrl,
                                videoUrl: videoUrl,
                              );

                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                rootMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Post publicado!'),
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

class _GroupHeader extends StatelessWidget {
  final CommunityGroup group;
  final String creatorName;
  final bool isMember;
  final bool isCreator;

  const _GroupHeader({
    required this.group,
    required this.creatorName,
    required this.isMember,
    required this.isCreator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ElevaColors.offWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ElevaColors.gold, ElevaColors.goldLight],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(group.icon, size: 24, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: ElevaColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 14, color: ElevaColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          'Criado por $creatorName',
                          style: const TextStyle(
                            fontSize: 12,
                            color: ElevaColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ElevaColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline_rounded,
                        size: 14, color: ElevaColors.gold),
                    const SizedBox(width: 4),
                    Text(
                      '${group.membersCount}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ElevaColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (group.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              group.description,
              style: const TextStyle(
                fontSize: 13,
                color: ElevaColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _JoinSection extends ConsumerStatefulWidget {
  final void Function(String message) onRequestJoin;
  final String groupId;

  const _JoinSection({
    required this.onRequestJoin,
    required this.groupId,
  });

  @override
  ConsumerState<_JoinSection> createState() => _JoinSectionState();
}

class _JoinSectionState extends ConsumerState<_JoinSection> {
  final _messageController = TextEditingController();
  static const _maxMessageLength = 200;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingRequests = ref.watch(userJoinRequestsProvider).value ?? {};
    final hasPending = pendingRequests.contains(widget.groupId);

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Icon(Icons.lock_outline_rounded,
                size: 48, color: ElevaColors.gold.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text(
              'Os posts deste grupo são\nvisíveis apenas para membros',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: ElevaColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            if (!hasPending) ...[
              TextField(
                controller: _messageController,
                maxLength: _maxMessageLength,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Mensagem para o dono (opcional)',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: hasPending
                    ? null
                    : () => widget.onRequestJoin(
                          _messageController.text.trim(),
                        ),
                icon: Icon(
                  hasPending
                      ? Icons.hourglass_top_rounded
                      : Icons.group_add_rounded,
                  size: 18,
                ),
                label: Text(
                    hasPending ? 'Solicitação pendente' : 'Solicitar entrada'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostsSection extends ConsumerWidget {
  final String groupId;
  final bool isCreator;
  final String currentUserId;

  const _PostsSection({
    required this.groupId,
    required this.isCreator,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(groupPostsProvider(groupId));

    return postsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: ElevaColors.gold),
      ),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(
            child: Text(
              'Nenhum post ainda.\nSeja o primeiro!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: ElevaColors.textMuted),
            ),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: posts.length,
              separatorBuilder: (_, __) => Container(height: 8, color: const Color(0xFFEEEEEE)),
              itemBuilder: (context, i) {
                final post = posts[i];
                final canDelete = isCreator || post.userId == currentUserId;
                return _GroupPostCard(
                  post: post,
                  canDelete: canDelete,
                  currentUserId: currentUserId,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _GroupPostCard extends ConsumerWidget {
  final GroupPost post;
  final bool canDelete;
  final String currentUserId;

  const _GroupPostCard({
    required this.post,
    required this.canDelete,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userLikes = ref.watch(groupPostLikesProvider).value ?? {};
    final isLiked = userLikes.contains(post.id);

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: ElevaColors.gold.withValues(alpha: 0.15),
                  child: Text(
                    post.avatarLetter,
                    style: const TextStyle(
                      fontSize: 15,
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
                      Text(
                        post.authorName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ElevaColors.textDark,
                        ),
                      ),
                      Text(
                        post.timeAgo,
                        style: const TextStyle(
                            fontSize: 12, color: ElevaColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (canDelete)
                  IconButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Excluir post'),
                          content: const Text('Tem certeza que deseja excluir este post?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Excluir'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      try {
                        await deleteGroupPost(post.id);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao excluir: $e'),
                              backgroundColor: Colors.red.shade400,
                            ),
                          );
                        }
                      }
                    },
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 20, color: Colors.red.shade300),
                    iconSize: 20,
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
              post.content,
              style: const TextStyle(
                fontSize: 14,
                color: ElevaColors.textMuted,
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    try {
                      await toggleGroupPostLike(post.id, currentUserId, isLiked);
                    } catch (_) {}
                  },
                  child: Row(
                    children: [
                      Icon(
                        isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 20,
                        color:
                            isLiked ? ElevaColors.gold : ElevaColors.textMuted,
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
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => _showComments(context),
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

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CommentsSheet(
        postId: post.id,
        postTitle: post.title,
      ),
    );
  }
}

class _CommentsSheet extends ConsumerStatefulWidget {
  final String postId;
  final String postTitle;

  const _CommentsSheet({
    required this.postId,
    required this.postTitle,
  });

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final profile = ref.read(userProfileProvider).value;
      final authorName = profile?.name ?? 'Anônimo';

      await addGroupPostComment(
        postId: widget.postId,
        userId: user.id,
        authorName: authorName,
        content: content,
      );

      _controller.clear();
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
    final commentsAsync =
        ref.watch(groupPostCommentsProvider(widget.postId));

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
              widget.postTitle,
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
                        'Nenhum comentário ainda.\nSeja o primeiro!',
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
                        _CommentItem(comment: comments[i]),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                        hintText: 'Escrever comentário...'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSending ? null : _sendComment,
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

class _CommentItem extends StatelessWidget {
  final GroupPostComment comment;
  const _CommentItem({required this.comment});

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


class _JoinRequestsSheet extends ConsumerWidget {
  final String groupId;
  const _JoinRequestsSheet({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(groupJoinRequestsProvider(groupId));

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
            'Solicitações de entrada',
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
                      'Nenhuma solicitação pendente',
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
                    .map((req) =>
                        _JoinRequestTile(request: req, groupId: groupId))
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

class _JoinRequestTile extends StatefulWidget {
  final GroupJoinRequest request;
  final String groupId;

  const _JoinRequestTile({required this.request, required this.groupId});

  @override
  State<_JoinRequestTile> createState() => _JoinRequestTileState();
}

class _JoinRequestTileState extends State<_JoinRequestTile> {
  bool _isLoading = false;

  Future<void> _respond(String status) async {
    setState(() => _isLoading = true);
    try {
      await respondToJoinRequest(
        requestId: widget.request.id,
        status: status,
        groupId: widget.groupId,
        userId: widget.request.userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'accepted'
                ? '${widget.request.userName} foi aceito!'
                : 'Solicitação recusada'),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: ElevaColors.gold.withValues(alpha: 0.15),
                child:
                    const Icon(Icons.person, size: 22, color: ElevaColors.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.request.userName,
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
          if (widget.request.message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(left: 56),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ElevaColors.offWhite,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.request.message,
                style: const TextStyle(
                  fontSize: 13,
                  color: ElevaColors.textDark,
                  fontStyle: FontStyle.italic,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
