class Post {
  final String id;
  final String userId;
  final String authorName;
  final String title;
  final String body;
  final bool isAdmin;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;

  const Post({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.title,
    required this.body,
    required this.isAdmin,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      authorName: map['author_name'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      isAdmin: map['is_admin'] as bool? ?? false,
      likesCount: map['likes_count'] as int? ?? 0,
      commentsCount: map['comments_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'author_name': authorName,
      'title': title,
      'body': body,
      'is_admin': isAdmin,
    };
  }

  String get avatarLetter =>
      isAdmin ? '✦' : (authorName.isNotEmpty ? authorName[0] : '?');

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays < 7) return 'há ${diff.inDays}d';
    return 'há ${(diff.inDays / 7).floor()}sem';
  }
}
