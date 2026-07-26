import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../models/community_group.dart';
import '../models/group_join_request.dart';
import '../models/group_post.dart';
import '../models/group_post_comment.dart';

final groupsProvider = StreamProvider<List<CommunityGroup>>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.value == null) return Stream.value([]);

  return Supabase.instance.client
      .from('groups')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows.map(CommunityGroup.fromMap).toList());
});

final userGroupMembershipsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value({});

  return Supabase.instance.client
      .from('group_members')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .map((rows) => rows.map((r) => r['group_id'] as String).toSet());
});

final groupJoinRequestsProvider =
    StreamProvider.family<List<GroupJoinRequest>, String>((ref, groupId) {
  return Supabase.instance.client
      .from('group_join_requests')
      .stream(primaryKey: ['id'])
      .eq('group_id', groupId)
      .order('created_at', ascending: false)
      .map((rows) => rows
          .map(GroupJoinRequest.fromMap)
          .where((r) => r.isPending)
          .toList());
});

final userJoinRequestsProvider = FutureProvider<Set<String>>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return {};

  final rows = await Supabase.instance.client
      .from('group_join_requests')
      .select('group_id')
      .eq('user_id', user.id)
      .eq('status', 'pending');

  return rows.map((r) => r['group_id'] as String).toSet();
});

final userOwnsGroupProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return false;

  final rows = await Supabase.instance.client
      .from('groups')
      .select('id')
      .eq('creator_id', user.id)
      .limit(1);

  return rows.isNotEmpty;
});

final groupPostsProvider =
    StreamProvider.family<List<GroupPost>, String>((ref, groupId) {
  return Supabase.instance.client
      .from('group_posts')
      .stream(primaryKey: ['id'])
      .eq('group_id', groupId)
      .order('created_at', ascending: false)
      .map((rows) => rows.map(GroupPost.fromMap).toList());
});

final groupPostLikesProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value({});

  return Supabase.instance.client
      .from('group_post_likes')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .map((rows) => rows.map((r) => r['post_id'] as String).toSet());
});

final groupPostCommentsProvider =
    StreamProvider.family<List<GroupPostComment>, String>((ref, postId) {
  if (ref.watch(authStateProvider).value == null) return Stream.value([]);

  return Supabase.instance.client
      .from('group_post_comments')
      .stream(primaryKey: ['id'])
      .eq('post_id', postId)
      .order('created_at', ascending: true)
      .map((rows) => rows.map(GroupPostComment.fromMap).toList());
});

Future<void> requestToJoinGroup({
  required String groupId,
  required String userId,
  required String userName,
  required String groupCreatorId,
  required String groupName,
  String message = '',
}) async {
  await Supabase.instance.client.from('group_join_requests').insert({
    'group_id': groupId,
    'user_id': userId,
    'user_name': userName,
    'message': message,
  });

  await createUserNotification(
    targetUserId: groupCreatorId,
    title: 'Solicitação de entrada',
    body: '$userName quer entrar no grupo "$groupName"',
    type: 'friend_request',
  );
}

Future<void> respondToJoinRequest({
  required String requestId,
  required String status,
  required String groupId,
  required String userId,
}) async {
  await Supabase.instance.client
      .from('group_join_requests')
      .update({'status': status}).eq('id', requestId);

  if (status == 'accepted') {
    await Supabase.instance.client.from('group_members').insert({
      'group_id': groupId,
      'user_id': userId,
    });
  }
}

Future<void> createGroupPost({
  required String groupId,
  required String userId,
  required String authorName,
  required String title,
  required String content,
}) async {
  await Supabase.instance.client.from('group_posts').insert({
    'group_id': groupId,
    'user_id': userId,
    'author_name': authorName,
    'title': title,
    'content': content,
  });
}

Future<void> deleteGroupPost(String postId) async {
  await Supabase.instance.client
      .from('group_posts')
      .delete()
      .eq('id', postId);
}

Future<void> toggleGroupPostLike(String postId, String userId, bool isLiked) async {
  if (isLiked) {
    await Supabase.instance.client
        .from('group_post_likes')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', userId);
  } else {
    await Supabase.instance.client.from('group_post_likes').insert({
      'post_id': postId,
      'user_id': userId,
    });
  }
}

Future<void> addGroupPostComment({
  required String postId,
  required String userId,
  required String authorName,
  required String content,
}) async {
  await Supabase.instance.client.from('group_post_comments').insert({
    'post_id': postId,
    'user_id': userId,
    'author_name': authorName,
    'content': content,
  });
}

Future<void> deleteGroup(String groupId) async {
  await Supabase.instance.client
      .from('groups')
      .delete()
      .eq('id', groupId);
}
