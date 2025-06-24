import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import '../services/notification_service.dart';
import '../services/navigation_service.dart';
import '../services/service_locator.dart';
import '../core/app_views.dart';

class NotificationCenterView extends StatefulWidget {
  const NotificationCenterView({super.key});

  @override
  State<NotificationCenterView> createState() => _NotificationCenterViewState();
}

class _NotificationCenterViewState extends State<NotificationCenterView> {
  final NotificationService _notificationService = getIt<NotificationService>();
  final NavigationService _navigationService = getIt<NavigationService>();

  @override
  void initState() {
    super.initState();
    _notificationService.addListener(_onNotificationsChanged);
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onNotificationsChanged);
    super.dispose();
  }

  void _onNotificationsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _notificationService.notifications.reversed.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: MacosScaffold(
        toolBar: ToolBar(
          title: Text('Notifications (${_notificationService.unreadCount})'),
          actions: [
            ToolBarIconButton(
              label: 'Clear All',
              icon: const MacosIcon(CupertinoIcons.clear_circled),
              onPressed: _notificationService.clearNotifications,
              showLabel: false,
            ),
            ToolBarIconButton(
              label: 'Back to Command Center',
              icon: const MacosIcon(CupertinoIcons.return_icon),
              onPressed: () =>
                  _navigationService.switchToView(AppView.commandCenter),
              showLabel: false,
            ),
          ],
        ),
        children: [
          ContentArea(
            builder: (context, scrollController) {
              if (notifications.isEmpty) {
                return const Center(
                  child: Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: MacosColors.systemGrayColor,
                    ),
                  ),
                );
              }
              return ListView.builder(
                controller: scrollController,
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final originalIndex = _notificationService.notifications.length - 1 - index;
                  return MacosListTile(
                    leading: MacosIcon(
                      notification['unread']
                          ? CupertinoIcons.bell_solid
                          : CupertinoIcons.bell,
                      color: notification['unread']
                          ? MacosTheme.of(context).primaryColor
                          : MacosColors.systemGrayColor,
                    ),
                    title: Text(
                      notification['title'],
                      style: TextStyle(
                        fontWeight: notification['unread']
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(notification['description']),
                    onClick: () =>
                        _notificationService.markAsRead(originalIndex),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}