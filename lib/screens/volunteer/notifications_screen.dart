import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';

/// Volunteer notification panel screen.
/// Accessible via route [/notifications] or pushed directly.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  AppNotification? _expanded; // tapped notification shown in-place expanded

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications(reset: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationProvider>().loadMore();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight1,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
      ),
      elevation: 0,
      title: Text(
        'Notifications',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        Consumer<NotificationProvider>(
          builder: (_, prov, __) => prov.unreadCount > 0
              ? TextButton(
                  onPressed: () => prov.markAllAsRead(),
                  child: Text(
                    'Mark all read',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Consumer<NotificationProvider>(
      builder: (_, prov, __) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _filterChip('All', 'all', prov),
              const SizedBox(width: 8),
              _filterChip('Unread', 'unread', prov),
              const SizedBox(width: 8),
              _filterChip('Read', 'read', prov),
            ],
          ),
        );
      },
    );
  }

  Widget _filterChip(
      String label, String value, NotificationProvider prov) {
    final selected = prov.currentFilter == value;
    return GestureDetector(
      onTap: () {
        if (!selected) {
          setState(() => _expanded = null);
          prov.loadNotifications(reset: true, filter: value);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                selected ? AppColors.primaryBlue : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.gray1,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<NotificationProvider>(
      builder: (_, prov, __) {
        if (prov.isLoading) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primaryBlue));
        }

        if (prov.error != null) {
          return _errorView(prov);
        }

        if (prov.notifications.isEmpty) {
          return _emptyView(prov.currentFilter);
        }

        return RefreshIndicator(
          color: AppColors.primaryBlue,
          onRefresh: () =>
              prov.loadNotifications(reset: true),
          child: ListView.separated(
            controller: _scrollController,
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount:
                prov.notifications.length + (prov.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (ctx, i) {
              if (i == prov.notifications.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryBlue)),
                );
              }
              return _notificationTile(prov.notifications[i], prov);
            },
          ),
        );
      },
    );
  }

  Widget _errorView(NotificationProvider prov) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text('Failed to load notifications',
              style: GoogleFonts.poppins(
                  color: Colors.grey.shade700, fontSize: 15)),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue),
            onPressed: () => prov.loadNotifications(reset: true),
            child:
                Text('Retry', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _emptyView(String filter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            filter == 'unread'
                ? 'No unread notifications'
                : filter == 'read'
                    ? 'No read notifications'
                    : 'No notifications yet',
            style: GoogleFonts.poppins(
                fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Single notification tile
  // ---------------------------------------------------------------------------

  Widget _notificationTile(
      AppNotification n, NotificationProvider prov) {
    final typeColor = n.type.color;
    final isExpanded = _expanded?.id == n.id;

    return GestureDetector(
      onTap: () {
        // Mark as read on tap
        prov.markAsRead(n.id);
        setState(() {
          _expanded = isExpanded ? null : n;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.white : typeColor.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: n.isRead
                ? Colors.grey.shade200
                : typeColor.withOpacity(0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Colour stripe
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(n.type.icon,
                            color: typeColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Unread dot
                                if (!n.isRead) ...[
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: typeColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                                Expanded(
                                  child: Text(
                                    n.title,
                                    style: GoogleFonts.poppins(
                                      fontWeight: n.isRead
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              n.message,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                              maxLines: isExpanded ? null : 2,
                              overflow: isExpanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        typeColor.withOpacity(0.12),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    n.type.label,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: typeColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _relativeTime(n.createdAt),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Delete button
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 18, color: Colors.grey),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          if (_expanded?.id == n.id) {
                            setState(() => _expanded = null);
                          }
                          prov.deleteNotification(n.id);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min${diff.inMinutes > 1 ? 's' : ''} ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    }
    return DateFormat('MMM d, yyyy').format(dt);
  }
}
