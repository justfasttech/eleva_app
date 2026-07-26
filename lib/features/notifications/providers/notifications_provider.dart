import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_provider.dart';
import '../../verses/models/daily_verse.dart';
import '../models/app_notification.dart';

final notificationsProvider =
    StreamProvider<List<AppNotification>>((ref) async* {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    yield [];
    return;
  }

  final client = Supabase.instance.client;

  try {
    await _ensureDailyVerse(client);
  } catch (_) {
    // RLS blocks non-admin inserts; verse still shown via todayVerseProvider
  }

  final readIds = <String>{};

  await for (final rows in client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)) {
    final readRows = await client
        .from('notification_reads')
        .select('notification_id')
        .eq('user_id', user.id);

    readIds
      ..clear()
      ..addAll(readRows.map((r) => r['notification_id'] as String));

    yield rows
        .map((row) {
          final id = row['id'] as String;
          return AppNotification.fromMap(row, isRead: readIds.contains(id));
        })
        .where((n) => !n.isRead)
        .toList();
  }
});

final unreadCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider).value ?? [];
  return notifs.where((n) => !n.isRead).length;
});

Future<void> _ensureDailyVerse(SupabaseClient client) async {
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);

  final existing = await client
      .from('notifications')
      .select('id')
      .eq('type', 'daily_verse')
      .gte('created_at', startOfDay.toIso8601String())
      .limit(1);

  if (existing.isNotEmpty) return;

  final rows = await client
      .from('daily_verses')
      .select()
      .eq('is_active', true);

  if (rows.isEmpty) return;

  final seed = today.year * 10000 + today.month * 100 + today.day;
  final index = Random(seed).nextInt(rows.length);
  final verse = DailyVerse.fromMap(rows[index]);

  await client.from('notifications').insert({
    'title': verse.source.isNotEmpty ? verse.source : 'Versículo do dia',
    'body': verse.text,
    'type': 'daily_verse',
    'audience': 'todos',
  });
}

Future<void> markAsRead(String notificationId, String userId) async {
  try {
    await Supabase.instance.client.from('notification_reads').insert({
      'notification_id': notificationId,
      'user_id': userId,
    });
  } catch (_) {
    // Already marked as read (conflict) — ignore
  }
}

Future<void> createUserNotification({
  required String targetUserId,
  required String title,
  required String body,
  required String type,
}) async {
  try {
    await Supabase.instance.client.from('notifications').insert({
      'title': title,
      'body': body,
      'type': type,
      'audience': 'todos',
      'target_user_id': targetUserId,
    });
  } catch (_) {}
}

Future<void> markAllAsRead(List<String> notificationIds, String userId) async {
  if (notificationIds.isEmpty) return;

  final client = Supabase.instance.client;

  final rows = notificationIds
      .map((id) => {
            'notification_id': id,
            'user_id': userId,
          })
      .toList();

  for (final row in rows) {
    try {
      await client.from('notification_reads').insert(row);
    } catch (_) {
      // Already marked as read — ignore
    }
  }
}
