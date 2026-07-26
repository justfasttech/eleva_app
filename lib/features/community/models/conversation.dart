class Conversation {
  final String id;
  final String user1Id;
  final String user2Id;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final String otherUserName;

  const Conversation({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.lastMessageText,
    this.lastMessageAt,
    required this.createdAt,
    required this.otherUserName,
  });

  factory Conversation.fromMap(
    Map<String, dynamic> map,
    String currentUserId,
    String otherName,
  ) {
    return Conversation(
      id: map['id'] as String,
      user1Id: map['user1_id'] as String,
      user2Id: map['user2_id'] as String,
      lastMessageText: map['last_message_text'] as String?,
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.parse(map['last_message_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      otherUserName: otherName,
    );
  }

  String get avatarLetter =>
      otherUserName.isNotEmpty ? otherUserName[0] : '?';

  String otherUserId(String currentUserId) =>
      currentUserId == user1Id ? user2Id : user1Id;

  String get timeLabel {
    final dt = lastMessageAt;
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays == 1) return 'ontem';
    return '${dt.day}/${dt.month.toString().padLeft(2, '0')}';
  }
}
