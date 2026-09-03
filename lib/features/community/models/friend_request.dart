class FriendRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String fromUserName;
  final String status;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromUserName,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromMap(Map<String, dynamic> map) {
    return FriendRequest(
      id: map['id'] as String,
      fromUserId: map['from_user_id'] as String,
      toUserId: map['to_user_id'] as String,
      fromUserName: map['from_user_name'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'from_user_name': fromUserName,
    };
  }

  bool get isPending => status == 'pending';

  String get avatarLetter =>
      fromUserName.isNotEmpty ? fromUserName[0] : '?';
}
