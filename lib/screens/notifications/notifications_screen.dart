import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/models/notification_model.dart';
import 'package:soilsocial/services/notification_service.dart';
import 'package:soilsocial/config/theme.dart';
import 'package:soilsocial/l10n/app_localizations.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    final notifService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.translate('notifications')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.dividerColor, height: 1),
        ),
        actions: [
          TextButton(
            onPressed: () => notifService.markAllAsRead(uid),
            child: Text(l.translate('markAllRead')),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notifService.getNotifications(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            );
          }
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 56,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.translate('noNotifications'),
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final n = notifications[index];
              return _NotificationTile(
                notification: n,
                notifService: notifService,
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final NotificationService notifService;
  const _NotificationTile({
    required this.notification,
    required this.notifService,
  });

  IconData _icon() {
    switch (notification.type) {
      case NotificationType.connection:
        return Icons.person_add;
      case NotificationType.like:
        return Icons.thumb_up;
      case NotificationType.comment:
        return Icons.chat_bubble_outline;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.event:
        return Icons.event;
      case NotificationType.marketplace:
        return Icons.storefront;
    }
  }

  void _onTap(BuildContext context) {
    if (!notification.read) {
      notifService.markAsRead(notification.id);
    }
    final id = notification.relatedId;
    if (id == null) return;

    switch (notification.type) {
      case NotificationType.connection:
        context.push('/profile/$id');
        break;
      case NotificationType.like:
      case NotificationType.comment:
        break;
      case NotificationType.message:
        context.push('/messages/$id', extra: {'name': notification.senderName});
        break;
      case NotificationType.event:
        context.push('/events/$id');
        break;
      case NotificationType.marketplace:
        context.push('/marketplace/$id');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notification.read
          ? Colors.white
          : AppTheme.primaryGreen.withValues(alpha: 0.04),
      child: ListTile(
        onTap: () => _onTap(context),
        leading: notification.senderProfilePicture != null
            ? CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(
                  notification.senderProfilePicture!,
                ),
              )
            : CircleAvatar(
                backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                child: Icon(_icon(), color: AppTheme.primaryGreen, size: 20),
              ),
        title: Text(
          notification.content,
          style: TextStyle(
            fontWeight: notification.read ? FontWeight.normal : FontWeight.w600,
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          timeago.format(notification.createdAt),
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: notification.read
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }
}
