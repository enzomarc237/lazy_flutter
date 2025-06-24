import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';

class NotificationCenterView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<NotificationService>(
          builder: (context, notificationService, child) {
            return Text('Notifications (${notificationService.unreadCount})');
          },
        ),
      ),
      body: ListView.builder(
        itemCount: context.watch<NotificationService>().notifications.length,
        itemBuilder: (context, index) {
          final notification = context.watch<NotificationService>().notifications[index];
          return ListTile(
            title: Text(notification['title']),
            subtitle: Text(notification['description']),
            trailing: Icon(
              notification['unread'] ? Icons.notifications_active : Icons.notifications,
            ),
            onTap: () {
              context.read<NotificationService>().markAsRead(index);
            },
          );
        },
      ),
    );
  }
}