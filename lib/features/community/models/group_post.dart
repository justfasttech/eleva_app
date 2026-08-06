class GroupPost {
  final String id;
  final String groupId;
  final String userId;
  final String authorName;
  final String title;
  final String content;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final String? imageUrl;
  final String? videoUrl;
  final bool isQuestion;

  const GroupPost({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.authorName,
    required this.title,
    required this.content,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    this.imageUrl,
    this.videoUrl,
    this.isQuestion = false,
  });

  factory GroupPost.fromMap(Map<String, dynamic> map) {
    return GroupPost(
      id: map['id'] as String,
      groupId: map['group_id'] as String,
      userId: map['user_id'] as String,
      authorName: map['author_name'] as String? ?? '',
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      likesCount: map['likes_count'] as int? ?? 0,
      commentsCount: map['comments_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      imageUrl: map['image_url'] as String?,
      videoUrl: map['video_url'] as String?,
      isQuestion: map['is_question'] as bool? ?? false,
    );
  }

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  String get avatarLetter =>
      authorName.isNotEmpty ? authorName[0] : '?';

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays < 7) return 'há ${diff.inDays}d';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
