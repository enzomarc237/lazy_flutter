import 'package:flutter/widgets.dart';

// Data model for a command in the palette
class Command {
  final String title;
  final IconData icon;
  final VoidCallback action;
  final int? badgeCount; // Optional: for notification-style badges

  Command({
    required this.title,
    required this.icon,
    required this.action,
    this.badgeCount,
  });
}
