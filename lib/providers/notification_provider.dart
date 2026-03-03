import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// Global state for volunteer notifications.
///
/// Wrap [MaterialApp] with [ChangeNotifierProvider<NotificationProvider>].
/// The provider tracks unread count + the current notification list and
/// exposes all mutating actions (mark read, delete, load more, etc.).
class NotificationProvider extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // Internal storage
  // ---------------------------------------------------------------------------
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ---------------------------------------------------------------------------
  // Public state
  // ---------------------------------------------------------------------------
  int unreadCount = 0;
  List<AppNotification> notifications = [];
  String currentFilter = 'all'; // all | read | unread
  int _currentPage = 1;
  int _totalPages = 1;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool isInitialized = false;
  String? error;

  Timer? _pollTimer;

  // ---------------------------------------------------------------------------
  // Bootstrap helpers
  // ---------------------------------------------------------------------------

  /// Call once after login to start polling and load first page.
  Future<void> init() async {
    if (isInitialized) return;
    isInitialized = true;
    await refreshCount();
    await loadNotifications(reset: true);
    _startPolling();
  }

  /// Call on logout to reset everything.
  void reset() {
    _pollTimer?.cancel();
    _pollTimer = null;
    unreadCount = 0;
    notifications = [];
    currentFilter = 'all';
    _currentPage = 1;
    _totalPages = 1;
    isLoading = false;
    isLoadingMore = false;
    isInitialized = false;
    error = null;
    notifyListeners();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      await refreshCount();
    });
  }

  // ---------------------------------------------------------------------------
  // Token helper
  // ---------------------------------------------------------------------------
  Future<String?> _token() async {
    final raw = await _storage.read(key: 'userData');
    if (raw == null) return null;
    final decoded = json.decode(raw);
    return (decoded['token'] ?? decoded['accessToken']) as String?;
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Refresh only the unread badge count.
  Future<void> refreshCount() async {
    final token = await _token();
    if (token == null) return;
    try {
      final counts = await NotificationService.getNotificationCount(token);
      unreadCount = counts['unread'] ?? 0;
      notifyListeners();
    } catch (_) {
      // Silently ignore polling errors
    }
  }

  /// Load (or reload) the notifications list.
  Future<void> loadNotifications({
    bool reset = false,
    String? filter,
  }) async {
    final token = await _token();
    if (token == null) return;

    if (reset) {
      _currentPage = 1;
      _totalPages = 1;
      notifications = [];
      currentFilter = filter ?? currentFilter;
    } else if (filter != null && filter != currentFilter) {
      _currentPage = 1;
      _totalPages = 1;
      notifications = [];
      currentFilter = filter;
    }

    if (_currentPage > _totalPages && !reset) return;

    if (_currentPage == 1) {
      isLoading = true;
    } else {
      isLoadingMore = true;
    }
    error = null;
    notifyListeners();

    try {
      final result = await NotificationService.getMyNotifications(
        token,
        page: _currentPage,
        filter: currentFilter,
      );

      if (_currentPage == 1) {
        notifications = result.notifications;
      } else {
        notifications = [...notifications, ...result.notifications];
      }

      unreadCount = result.unreadCount;
      _totalPages = result.pages;
      _currentPage++;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Load the next page (infinite scroll / "Load More").
  Future<void> loadMore() async {
    if (isLoadingMore || _currentPage > _totalPages) return;
    await loadNotifications();
  }

  /// Mark a single notification as read on tap.
  Future<void> markAsRead(String id) async {
    final token = await _token();
    if (token == null) return;

    // Optimistic update
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    if (notifications[idx].isRead) return; // already read

    notifications[idx] = notifications[idx]
        .copyWith(isRead: true, readAt: DateTime.now());
    if (unreadCount > 0) unreadCount--;
    notifyListeners();

    try {
      await NotificationService.markOneAsRead(token, id);
    } catch (_) {
      // Roll back optimistic update on failure
      notifications[idx] =
          notifications[idx].copyWith(isRead: false, readAt: null);
      unreadCount++;
      notifyListeners();
    }
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() async {
    final token = await _token();
    if (token == null) return;

    // Optimistic update
    notifications = notifications
        .map((n) =>
            n.isRead ? n : n.copyWith(isRead: true, readAt: DateTime.now()))
        .toList();
    unreadCount = 0;
    notifyListeners();

    try {
      await NotificationService.markAllAsRead(token);
    } catch (e) {
      // Reload on failure
      await loadNotifications(reset: true);
    }
  }

  /// Delete a notification.
  Future<void> deleteNotification(String id) async {
    final token = await _token();
    if (token == null) return;

    final removed = notifications.firstWhere(
      (n) => n.id == id,
      orElse: () => AppNotification(
        id: '',
        title: '',
        message: '',
        type: NotificationType.general,
        isRead: true,
        emailSent: false,
        createdAt: DateTime.now(),
      ),
    );

    // Optimistic remove
    notifications = notifications.where((n) => n.id != id).toList();
    if (!removed.isRead && removed.id.isNotEmpty && unreadCount > 0) {
      unreadCount--;
    }
    notifyListeners();

    try {
      await NotificationService.deleteNotification(token, id);
    } catch (_) {
      // Re-insert on failure
      if (removed.id.isNotEmpty) {
        notifications = [removed, ...notifications];
        if (!removed.isRead) unreadCount++;
        notifyListeners();
      }
    }
  }

  bool get hasMore => _currentPage <= _totalPages;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
