import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

/// Notification bell icon with an unread-count red badge.
///
/// Typically placed in an AppBar's [actions] list.
/// Tapping opens [NotificationsScreen] as a bottom sheet.
class NotificationBell extends StatelessWidget {
  /// Background colour for the icon (defaults to white – suitable for coloured
  /// app bars where the icon itself should be white).
  final Color iconColor;

  const NotificationBell({
    super.key,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final count = provider.unreadCount;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: 'Notifications',
              icon: Icon(
                count > 0
                    ? Icons.notifications_rounded
                    : Icons.notifications_none_rounded,
                color: iconColor,
              ),
              onPressed: () => _openPanel(context, provider),
            ),
            if (count > 0)
              Positioned(
                top: 8,
                right: 8,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE74C3C),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _openPanel(BuildContext context, NotificationProvider provider) {
    // Make sure notifications are loaded
    if (provider.notifications.isEmpty && !provider.isLoading) {
      provider.loadNotifications(reset: true);
    }
    Navigator.pushNamed(context, '/notifications');
  }
}
