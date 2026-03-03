import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/notification_model.dart';

/// All API communication for notifications.
class NotificationService {
  static String get _base => ApiConfig.apiUrl;

  // ---------------------------------------------------------------------------
  // Shared helper
  // ---------------------------------------------------------------------------

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      };

  // ---------------------------------------------------------------------------
  // VOLUNTEER APIs
  // ---------------------------------------------------------------------------

  /// GET /api/notifications?page=&limit=&filter=
  static Future<PaginatedNotifications> getMyNotifications(
    String token, {
    int page = 1,
    int limit = 20,
    String filter = 'all', // all | read | unread
  }) async {
    final uri = Uri.parse(
        '$_base/notifications?page=$page&limit=$limit&filter=$filter');
    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      final data = body['data'];
      final items = (data['notifications'] as List)
          .map((e) => AppNotification.fromJson(e))
          .toList();
      return PaginatedNotifications(
        notifications: items,
        total: data['total'] ?? 0,
        unreadCount: data['unreadCount'] ?? 0,
        page: data['page'] ?? page,
        pages: data['pages'] ?? 1,
      );
    }
    throw Exception('Failed to load notifications (${res.statusCode})');
  }

  /// GET /api/notifications/count
  static Future<Map<String, int>> getNotificationCount(String token) async {
    final uri = Uri.parse('$_base/notifications/count');
    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) {
      final data = json.decode(res.body)['data'];
      return {
        'total': (data['total'] ?? 0) as int,
        'unread': (data['unread'] ?? 0) as int,
        'read': (data['read'] ?? 0) as int,
      };
    }
    throw Exception('Failed to fetch count (${res.statusCode})');
  }

  /// PATCH /api/notifications/:id/read
  static Future<AppNotification> markOneAsRead(
      String token, String id) async {
    final uri = Uri.parse('$_base/notifications/$id/read');
    final res = await http.patch(uri, headers: _headers(token));
    if (res.statusCode == 200) {
      final data = json.decode(res.body)['data'];
      return AppNotification.fromJson(data);
    }
    throw Exception('Failed to mark as read (${res.statusCode})');
  }

  /// PATCH /api/notifications/read-all
  static Future<int> markAllAsRead(String token) async {
    final uri = Uri.parse('$_base/notifications/read-all');
    final res = await http.patch(uri, headers: _headers(token));
    if (res.statusCode == 200) {
      final data = json.decode(res.body)['data'];
      return (data['modifiedCount'] ?? 0) as int;
    }
    throw Exception('Failed to mark all as read (${res.statusCode})');
  }

  /// DELETE /api/notifications/:id
  static Future<void> deleteNotification(String token, String id) async {
    final uri = Uri.parse('$_base/notifications/$id');
    final res = await http.delete(uri, headers: _headers(token));
    if (res.statusCode != 200) {
      throw Exception('Failed to delete notification (${res.statusCode})');
    }
  }

  // ---------------------------------------------------------------------------
  // ADMIN APIs
  // ---------------------------------------------------------------------------

  /// POST /api/admin/notifications/send
  static Future<Map<String, dynamic>> sendNotification(
    String token, {
    required String title,
    required String message,
    required String type,
    required dynamic recipients, // "all" | List<String>
    bool sendEmail = true,
  }) async {
    final uri = Uri.parse('$_base/admin/notifications/send');
    final res = await http.post(
      uri,
      headers: _headers(token),
      body: json.encode({
        'title': title,
        'message': message,
        'type': type,
        'recipients': recipients,
        'sendEmail': sendEmail,
      }),
    );
    final body = json.decode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception(
        body['message'] ?? 'Failed to send notification (${res.statusCode})');
  }

  /// GET /api/admin/notifications/sent?page=&limit=
  static Future<PaginatedNotifications> getSentNotifications(
    String token, {
    int page = 1,
    int limit = 20,
  }) async {
    final uri =
        Uri.parse('$_base/admin/notifications/sent?page=$page&limit=$limit');
    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) {
      final data = json.decode(res.body)['data'];
      final items = (data['notifications'] as List)
          .map((e) => AppNotification.fromJson(e))
          .toList();
      return PaginatedNotifications(
        notifications: items,
        total: data['total'] ?? 0,
        page: data['page'] ?? page,
        pages: data['pages'] ?? 1,
      );
    }
    throw Exception(
        'Failed to load sent notifications (${res.statusCode})');
  }

  /// GET /api/admin/notifications/stats
  static Future<NotificationStats> getStats(String token) async {
    final uri = Uri.parse('$_base/admin/notifications/stats');
    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) {
      final data = json.decode(res.body)['data'];
      return NotificationStats.fromJson(data);
    }
    throw Exception('Failed to load stats (${res.statusCode})');
  }

  /// GET /api/admin/volunteers (used for recipient multi-select)
  static Future<List<Map<String, dynamic>>> getVolunteers(
      String token) async {
    final uri = Uri.parse('$_base/admin/volunteers');
    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      final list = body['volunteers'] ?? body['data'] ?? [];
      return List<Map<String, dynamic>>.from(list);
    }
    throw Exception('Failed to load volunteers (${res.statusCode})');
  }
}
