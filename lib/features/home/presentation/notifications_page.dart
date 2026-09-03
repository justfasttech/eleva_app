import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/models/app_notification.dart';
import '../../notifications/providers/notifications_provider.dart';
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);
    final userId = ref.watch(authStateProvider).value?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        centerTitle: true,
        actions: [
          if (userId != null)
            TextButton(
              onPressed: () async {
                final notifs = ref.read(notificationsProvider).value ?? [];
                final ids = notifs.map((n) => n.id).toList();
                await markAllAsRead(ids, userId);
                ref.invalidate(notificationsProvider);
              },
              child: const Text(
                'Limpar todas',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ElevaColors.gold,
                ),
              ),
            ),
        ],
      ),
      body: notifsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: ElevaColors.gold),
        ),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma notificação',
                style: TextStyle(fontSize: 14, color: ElevaColors.textMuted),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return Dismissible(
                key: ValueKey(notif.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: ElevaColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: ElevaColors.gold, size: 28),
                ),
                onDismissed: (_) async {
                  if (userId != null) {
                    await markAsRead(notif.id, userId);
                    ref.invalidate(notificationsProvider);
                  }
                },
                child: _NotificationCard(
                  notification: notif,
                  onMarkRead: () async {
                    if (userId != null) {
                      await markAsRead(notif.id, userId);
                      ref.invalidate(notificationsProvider);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onMarkRead;

  const _NotificationCard({
    required this.notification,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final n = notification;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ElevaColors.gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: ElevaColors.gold.withValues(alpha: 0.15), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: n.isDailyVerse
                  ? ElevaColors.gold.withValues(alpha: 0.15)
                  : ElevaColors.offWhite,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              n.isDailyVerse
                  ? Icons.format_quote_rounded
                  : Icons.notifications_rounded,
              size: 20,
              color: ElevaColors.gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ElevaColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  n.body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ElevaColors.textMuted,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  n.timeAgo,
                  style: TextStyle(
                    fontSize: 11,
                    color: ElevaColors.textMuted.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onMarkRead,
                    icon: const Icon(Icons.check_circle_outline_rounded,
                        size: 18, color: ElevaColors.gold),
                    label: const Text(
                      'Marcar como lido',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ElevaColors.gold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: ElevaColors.gold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
