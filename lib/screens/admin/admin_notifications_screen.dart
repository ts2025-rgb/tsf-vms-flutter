import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

/// Admin Notifications screen.
///
/// Tab 1 – Send Notification form.
/// Tab 2 – Sent Notifications log with stats and pagination.
class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _token;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadToken();
  }

  Future<void> _loadToken() async {
    final raw = await _storage.read(key: 'adminToken');
    setState(() => _token = raw);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight1,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.send_rounded), text: 'Send'),
            Tab(
                icon: Icon(Icons.history_rounded),
                text: 'Sent Log'),
          ],
        ),
      ),
      body: _token == null
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primaryBlue))
          : TabBarView(
              controller: _tabController,
              children: [
                _SendTab(token: _token!),
                _SentLogTab(token: _token!),
              ],
            ),
    );
  }
}

// =============================================================================
// TAB 1 – Send Notification
// =============================================================================

class _SendTab extends StatefulWidget {
  final String token;
  const _SendTab({required this.token});

  @override
  State<_SendTab> createState() => _SendTabState();
}

class _SendTabState extends State<_SendTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  NotificationType _type = NotificationType.general;
  String _recipientMode = 'all'; // all | specific
  bool _sendEmail = true;
  bool _sending = false;

  // Volunteer list for specific recipients
  List<Map<String, dynamic>> _volunteers = [];
  bool _loadingVolunteers = false;
  final Set<String> _selectedIds = {};
  String _volunteerSearch = '';

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadVolunteers() async {
    if (_volunteers.isNotEmpty) return;
    setState(() => _loadingVolunteers = true);
    try {
      final list =
          await NotificationService.getVolunteers(widget.token);
      setState(() {
        _volunteers = list;
        _loadingVolunteers = false;
      });
    } catch (e) {
      setState(() => _loadingVolunteers = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load volunteers: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_recipientMode == 'specific' && _selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please select at least one volunteer.')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final data = await NotificationService.sendNotification(
        widget.token,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        type: _type.value,
        recipients: _recipientMode == 'all'
            ? 'all'
            : _selectedIds.toList(),
        sendEmail: _sendEmail,
      );

      if (mounted) {
        final created = data['created'] ?? 0;
        final emails = data['emailsSent'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.accentGreen,
            content: Text(
              'Sent to $created user${created != 1 ? 's' : ''},'
              ' $emails email${emails != 1 ? 's' : ''} delivered.',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        );
        _formKey.currentState!.reset();
        _titleController.clear();
        _messageController.clear();
        setState(() {
          _type = NotificationType.general;
          _recipientMode = 'all';
          _sendEmail = true;
          _selectedIds.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFE74C3C),
            content: Text('Error: $e',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionCard(children: [
              _label('Title'),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecor('Enter notification title'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              _label('Message'),
              TextFormField(
                controller: _messageController,
                decoration: _inputDecor('Write your message…'),
                maxLines: 4,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Message is required'
                    : null,
              ),
            ]),
            const SizedBox(height: 12),
            _sectionCard(children: [
              _label('Type'),
              DropdownButtonFormField<NotificationType>(
                value: _type,
                decoration: _inputDecor(null),
                items: NotificationType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: t.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(t.label,
                                  style: GoogleFonts.poppins(fontSize: 14)),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
            ]),
            const SizedBox(height: 12),
            _sectionCard(children: [
              _label('Recipients'),
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: 'all',
                groupValue: _recipientMode,
                title: Text('All Volunteers',
                    style: GoogleFonts.poppins(fontSize: 14)),
                onChanged: (v) => setState(() => _recipientMode = v!),
                activeColor: AppColors.primaryBlue,
              ),
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: 'specific',
                groupValue: _recipientMode,
                title: Text('Specific Volunteers',
                    style: GoogleFonts.poppins(fontSize: 14)),
                onChanged: (v) {
                  setState(() => _recipientMode = v!);
                  _loadVolunteers();
                },
                activeColor: AppColors.primaryBlue,
              ),
              if (_recipientMode == 'specific') _buildVolunteerSelector(),
            ]),
            const SizedBox(height: 12),
            _sectionCard(children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Send Email Notification',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: Text(
                    'An email will be sent to each recipient',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey.shade600)),
                value: _sendEmail,
                activeColor: AppColors.primaryBlue,
                onChanged: (v) => setState(() => _sendEmail = v),
              ),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _sending ? 'Sending…' : 'Send Notification',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
                onPressed: _sending ? null : _submit,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildVolunteerSelector() {
    if (_loadingVolunteers) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
            child: CircularProgressIndicator(
                color: AppColors.primaryBlue)),
      );
    }

    final filtered = _volunteers.where((v) {
      final name =
          ((v['fullName'] ?? '') as String).toLowerCase();
      final code =
          ((v['volunteerCode'] ?? '') as String).toLowerCase();
      final q = _volunteerSearch.toLowerCase();
      return name.contains(q) || code.contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        TextField(
          decoration:
              _inputDecor('Search volunteers…').copyWith(
            prefixIcon: const Icon(Icons.search, size: 18),
          ),
          onChanged: (v) => setState(() => _volunteerSearch = v),
        ),
        const SizedBox(height: 8),
        if (_selectedIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '${_selectedIds.length} volunteer${_selectedIds.length > 1 ? 's' : ''} selected',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600),
            ),
          ),
        Container(
          constraints: const BoxConstraints(maxHeight: 240),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No volunteers found',
                      style: GoogleFonts.poppins(
                          color: Colors.grey.shade500, fontSize: 13)),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final v = filtered[i];
                    final id = v['_id'] as String? ?? '';
                    final name = v['fullName'] as String? ?? '';
                    final code =
                        v['volunteerCode'] as String? ?? '';
                    final selected = _selectedIds.contains(id);
                    return CheckboxListTile(
                      dense: true,
                      value: selected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedIds.add(id);
                          } else {
                            _selectedIds.remove(id);
                          }
                        });
                      },
                      title: Text(name,
                          style: GoogleFonts.poppins(fontSize: 13)),
                      subtitle: code.isNotEmpty
                          ? Text(code,
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey.shade500))
                          : null,
                      activeColor: AppColors.primaryBlue,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textDark),
      ),
    );
  }

  InputDecoration _inputDecor(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
          fontSize: 13, color: Colors.grey.shade400),
      filled: true,
      fillColor: AppColors.backgroundLight1,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
    );
  }
}

// =============================================================================
// TAB 2 – Sent Notifications Log
// =============================================================================

class _SentLogTab extends StatefulWidget {
  final String token;
  const _SentLogTab({required this.token});

  @override
  State<_SentLogTab> createState() => _SentLogTabState();
}

class _SentLogTabState extends State<_SentLogTab> {
  NotificationStats? _stats;
  List<AppNotification> _notifications = [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  int _totalPages = 1;
  bool _loadingMore = false;
  NotificationType? _typeFilter;
  final Set<String> _expandedIds = {};

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >=
              _scroll.position.maxScrollExtent - 200 &&
          !_loadingMore &&
          _page <= _totalPages) {
        _loadMore();
      }
    });
    _loadAll();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
      _notifications = [];
    });
    await Future.wait([_fetchStats(), _fetchPage(1)]);
  }

  Future<void> _fetchStats() async {
    try {
      final s = await NotificationService.getStats(widget.token);
      if (mounted) setState(() => _stats = s);
    } catch (_) {}
  }

  Future<void> _fetchPage(int page) async {
    try {
      final result = await NotificationService.getSentNotifications(
        widget.token,
        page: page,
        limit: 20,
      );
      if (mounted) {
        setState(() {
          if (page == 1) {
            _notifications = result.notifications;
          } else {
            _notifications = [..._notifications, ...result.notifications];
          }
          _totalPages = result.pages;
          _page = page + 1;
          _loading = false;
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page > _totalPages) return;
    setState(() => _loadingMore = true);
    await _fetchPage(_page);
  }

  // ---------- filtered list ----------
  List<AppNotification> get _filtered => _typeFilter == null
      ? _notifications
      : _notifications.where((n) => n.type == _typeFilter).toList();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primaryBlue,
      onRefresh: _loadAll,
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildStatsCards()),
          SliverToBoxAdapter(child: _buildTypeFilter()),
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryBlue)),
            )
          else if (_error != null)
            SliverFillRemaining(child: _errorView())
          else if (_filtered.isEmpty)
            SliverFillRemaining(child: _emptyView())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  if (i == _filtered.length) {
                    return _loadingMore
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primaryBlue)),
                          )
                        : const SizedBox(height: 40);
                  }
                  return _logRow(_filtered[i]);
                },
                childCount:
                    _filtered.length + (_loadingMore ? 1 : 0),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_stats == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: Row(
        children: [
          _statCard('Total Sent', _stats!.total, AppColors.primaryBlue,
              Icons.send_rounded),
          const SizedBox(width: 8),
          _statCard('Read', _stats!.read, AppColors.accentGreen,
              Icons.mark_email_read_rounded),
          const SizedBox(width: 8),
          _statCard('Unread', _stats!.unread, const Color(0xFFE74C3C),
              Icons.mark_email_unread_rounded),
        ],
      ),
    );
  }

  Widget _statCard(
      String label, int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          _typeChip(null, 'All'),
          ...NotificationType.values
              .map((t) => _typeChip(t, t.label)),
        ],
      ),
    );
  }

  Widget _typeChip(NotificationType? type, String label) {
    final selected = _typeFilter == type;
    final color =
        type != null ? type.color : AppColors.primaryBlue;
    return GestureDetector(
      onTap: () => setState(() => _typeFilter = type),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : Colors.grey.shade300),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _logRow(AppNotification n) {
    final typeColor = n.type.color;
    final user = n.user;
    final isExpanded = _expandedIds.contains(n.id);
    return GestureDetector(
      onTap: () => setState(() {
        if (isExpanded) {
          _expandedIds.remove(n.id);
        } else {
          _expandedIds.add(n.id);
        }
      }),
      child: Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? typeColor.withOpacity(0.35)
              : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored type icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(n.type.icon, color: typeColor, size: 20),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(n.title,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.textDark)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(n.type.label,
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: typeColor,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: Text(n.message,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  secondChild: Text(n.message,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.4)),
                ),
                // Show more / show less link
                GestureDetector(
                  onTap: () => setState(() {
                    if (isExpanded) {
                      _expandedIds.remove(n.id);
                    } else {
                      _expandedIds.add(n.id);
                    }
                  }),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      isExpanded ? 'Show less ▲' : 'Show more ▼',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: typeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (user != null)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.person_rounded,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${user.fullName}${user.volunteerCode != null ? ' · ${user.volunteerCode}' : ''}',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade600),
                        ),
                      ]),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        n.isRead
                            ? Icons.check_circle_outline_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 13,
                        color: n.isRead
                            ? AppColors.accentGreen
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(n.isRead ? 'Read' : 'Unread',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: n.isRead
                                  ? AppColors.accentGreen
                                  : Colors.grey.shade500)),
                    ]),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        n.emailSent
                            ? Icons.email_rounded
                            : Icons.email_outlined,
                        size: 13,
                        color: n.emailSent
                            ? AppColors.primaryBlue
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(n.emailSent ? 'Email sent' : 'No email',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: n.emailSent
                                  ? AppColors.primaryBlue
                                  : Colors.grey.shade500)),
                    ]),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.access_time_rounded,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy · h:mm a')
                            .format(n.createdAt.toLocal()),
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade500),
                      ),
                    ]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text('Failed to load sent notifications',
              style: GoogleFonts.poppins(
                  color: Colors.grey.shade700)),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue),
            onPressed: _loadAll,
            child: Text('Retry',
                style:
                    GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No notifications sent yet',
              style: GoogleFonts.poppins(
                  fontSize: 15, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
