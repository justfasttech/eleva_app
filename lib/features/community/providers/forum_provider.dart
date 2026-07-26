import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/post.dart';
import '../models/post_comment.dart';

final postsProvider = StreamProvider<List<Post>>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.value == null) return Stream.value([]);

  return Supabase.instance.client
      .from('posts')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows.map(Post.fromMap).toList());
});

final userLikesProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value({});

  return Supabase.instance.client
      .from('post_likes')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .map((rows) => rows.map((r) => r['post_id'] as String).toSet());
});

final postCommentsProvider =
    StreamProvider.family<List<PostComment>, String>((ref, postId) {
  if (ref.watch(authStateProvider).value == null) return Stream.value([]);

  return Supabase.instance.client
      .from('post_comments')
      .stream(primaryKey: ['id'])
      .eq('post_id', postId)
      .order('created_at', ascending: true)
      .map((rows) => rows.map(PostComment.fromMap).toList());
});
