import 'package:flutter/material.dart';

/// Notification types supported by the backend
enum NotificationType { general, announcement, alert, reminder, achievement }

extension NotificationTypeExt on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.general:
        return 'general';
      case NotificationType.announcement:
        return 'announcement';
      case NotificationType.alert:
        return 'alert';
      case NotificationType.reminder:
        return 'reminder';
      case NotificationType.achievement:
        return 'achievement';
    }
  }

  String get label {
    switch (this) {
      case NotificationType.general:
        return 'General';
      case NotificationType.announcement:
        return 'Announcement';
      case NotificationType.alert:
        return 'Alert';
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.achievement:
        return 'Achievement';
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.general:
        return const Color(0xFF4A90E2);
      case NotificationType.announcement:
        return const Color(0xFF7B68EE);
      case NotificationType.alert:
        return const Color(0xFFE74C3C);
      case NotificationType.reminder:
        return const Color(0xFFF39C12);
      case NotificationType.achievement:
        return const Color(0xFF27AE60);
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.general:
        return Icons.info_outline_rounded;
      case NotificationType.announcement:
        return Icons.campaign_rounded;
      case NotificationType.alert:
        return Icons.warning_amber_rounded;
      case NotificationType.reminder:
        return Icons.alarm_rounded;
      case NotificationType.achievement:
        return Icons.emoji_events_rounded;
    }
  }

  static NotificationType fromString(String? value) {
    switch (value) {
      case 'announcement':
        return NotificationType.announcement;
      case 'alert':
        return NotificationType.alert;
      case 'reminder':
        return NotificationType.reminder;
      case 'achievement':
        return NotificationType.achievement;
      default:
        return NotificationType.general;
    }
  }
}

/// Volunteer summary embedded in sent notifications (admin view)
class NotificationUser {
  final String id;
  final String fullName;
  final String email;
  final String? volunteerCode;

  const NotificationUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.volunteerCode,
  });

  factory NotificationUser.fromJson(Map<String, dynamic> json) {
    return NotificationUser(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      volunteerCode: json['volunteerCode'],
    );
  }
}

/// A single notification item
class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime? readAt;
  final bool emailSent;
  final DateTime createdAt;

  /// Populated user field (present in admin sent-notifications view)
  final NotificationUser? user;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.readAt,
    required this.emailSent,
    required this.createdAt,
    this.user,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final userRaw = json['userId'];
    NotificationUser? user;
    if (userRaw is Map<String, dynamic>) {
      user = NotificationUser.fromJson(userRaw);
    }

    return AppNotification(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: NotificationTypeExt.fromString(json['type']),
      isRead: json['isRead'] == true,
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt']) : null,
      emailSent: json['emailSent'] == true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      user: user,
    );
  }

  /// Copy with updated isRead flag
  AppNotification copyWith({bool? isRead, DateTime? readAt}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      emailSent: emailSent,
      createdAt: createdAt,
      user: user,
    );
  }
}

/// Paginated response wrapper
class PaginatedNotifications {
  final List<AppNotification> notifications;
  final int total;
  final int unreadCount;
  final int page;
  final int pages;

  const PaginatedNotifications({
    required this.notifications,
    required this.total,
    this.unreadCount = 0,
    required this.page,
    required this.pages,
  });
}

/// Stats from /api/admin/notifications/stats
class NotificationStats {
  final int total;
  final int read;
  final int unread;

  const NotificationStats({
    required this.total,
    required this.read,
    required this.unread,
  });

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      total: json['total'] ?? 0,
      read: json['read'] ?? 0,
      unread: json['unread'] ?? 0,
    );
  }
}
