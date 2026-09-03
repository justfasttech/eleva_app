class UserContentUnlock {
  final String id;
  final String userId;
  final String contentType;
  final String contentId;
  final DateTime unlockedAt;

  const UserContentUnlock({
    required this.id,
    required this.userId,
    required this.contentType,
    required this.contentId,
    required this.unlockedAt,
  });

  factory UserContentUnlock.fromMap(Map<String, dynamic> map) {
    return UserContentUnlock(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      contentType: map['content_type'] as String,
      contentId: map['content_id'] as String,
      unlockedAt: DateTime.parse(map['unlocked_at'] as String),
    );
  }
}
