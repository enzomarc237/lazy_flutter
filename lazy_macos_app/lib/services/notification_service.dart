import 'package:flutter/material.dart';

class NotificationService extends ChangeNotifier {
  final List<Map<String, dynamic>> _notifications = [];

  List<Map<String, dynamic>> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((notification) => notification['unread'] == true).length;

  void addNotification(String title, String description) {
    _notifications.add({'title': title, 'description': description, 'unread': true});
    notifyListeners();
  }

  void markAsRead(int index) {
    if (index >= 0 && index < _notifications.length) {
      _notifications[index]['unread'] = false;
      notifyListeners();
    }
  }

  void removeNotification(int index) {
    if (index >= 0 && index < _notifications.length) {
      _notifications.removeAt(index);
      notifyListeners();
    }
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }
}