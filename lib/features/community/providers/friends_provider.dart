import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/friend_data.dart';
import '../models/friend_request.dart';

final pendingFriendRequestsProvider =
    StreamProvider<List<FriendRequest>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  return Supabase.instance.client
      .from('friend_requests')
      .stream(primaryKey: ['id'])
      .eq('to_user_id', user.id)
      .map((rows) => rows
          .map(FriendRequest.fromMap)
          .where((r) => r.isPending)
          .toList());
});

final sentFriendRequestsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value({});

  return Supabase.instance.client
      .from('friend_requests')
      .stream(primaryKey: ['id'])
      .eq('from_user_id', user.id)
      .map((rows) => rows.map((r) => r['to_user_id'] as String).toSet());
});

final acceptedFriendsProvider = FutureProvider<List<FriendData>>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return [];

  final client = Supabase.instance.client;

  final rows = await client
      .from('friend_requests')
      .select()
      .eq('status', 'accepted')
      .or('from_user_id.eq.${user.id},to_user_id.eq.${user.id}');

  if (rows.isEmpty) return [];

  final friendIds = rows.map((row) {
    final fromId = row['from_user_id'] as String;
    final toId = row['to_user_id'] as String;
    return fromId == user.id ? toId : fromId;
  }).toSet().toList();

  if (friendIds.isEmpty) return [];

  final profiles = await client
      .from('profiles')
      .select('id, name, faith_level')
      .inFilter('id', friendIds);

  return profiles
      .map((p) => FriendData(
            id: p['id'] as String,
            name: p['name'] as String? ?? '',
            faithLevel: p['faith_level'] as int? ?? 0,
          ))
      .toList();
});
