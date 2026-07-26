class GroupJoinRequest {
  final String id;
  final String groupId;
  final String userId;
  final String userName;
  final String message;
  final String status;
  final DateTime createdAt;

  const GroupJoinRequest({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.userName,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory GroupJoinRequest.fromMap(Map<String, dynamic> map) {
    return GroupJoinRequest(
      id: map['id'] as String,
      groupId: map['group_id'] as String,
      userId: map['user_id'] as String,
      userName: map['user_name'] as String? ?? '',
      message: map['message'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  bool get isPending => status == 'pending';
}
