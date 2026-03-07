import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/models/notification_model.dart';
import 'package:soilsocial/services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    final notifService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => notifService.markAllAsRead(uid),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notifService.getNotifications(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications yet'));
          }

          return ListView.builder(
            itemCount: notifications.length,
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
        return Icons.favorite;
      case NotificationType.comment:
        return Icons.comment;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.event:
        return Icons.event;
      case NotificationType.marketplace:
        return Icons.store;
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
    return ListTile(
      onTap: () => _onTap(context),
      tileColor: notification.read
          ? null
          : Theme.of(context).colorScheme.primaryContainer.withAlpha(30),
      leading: notification.senderProfilePicture != null
          ? CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(
                notification.senderProfilePicture!,
              ),
            )
          : CircleAvatar(child: Icon(_icon())),
      title: Text(
        notification.content,
        style: TextStyle(
          fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Text(timeago.format(notification.createdAt)),
      trailing: notification.read
          ? null
          : Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
    );
  }
}
