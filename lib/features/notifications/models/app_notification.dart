class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final String audience;
  final String? targetUserId;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.audience,
    this.targetUserId,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, {bool isRead = false}) {
    return AppNotification(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      type: map['type'] as String? ?? 'admin',
      audience: map['audience'] as String? ?? 'todos',
      targetUserId: map['target_user_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      isRead: isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'audience': audience,
      if (targetUserId != null) 'target_user_id': targetUserId,
    };
  }

  bool get isDailyVerse => type == 'daily_verse';
  bool get isAdmin => type == 'admin';
  bool get isTargeted => targetUserId != null;

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays < 7) return 'há ${diff.inDays}d';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
