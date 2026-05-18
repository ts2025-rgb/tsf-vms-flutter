import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';
import '../../services/heartbeat_service.dart';

class HeartbeatAdminPage extends StatefulWidget {
  const HeartbeatAdminPage({super.key});

  @override
  State<HeartbeatAdminPage> createState() => _HeartbeatAdminPageState();
}

class _HeartbeatAdminPageState extends State<HeartbeatAdminPage>
    with SingleTickerProviderStateMixin {
  final HeartbeatService _service = HeartbeatService();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  late final TabController _tabController;
  final List<TextEditingController> _searchControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  final List<String> _selectedActivities = ['All', 'All'];
  final List<String> _selectedHours = ['All', 'All'];

  List<Map<String, dynamic>> _entries = [];
  List<Map<String, dynamic>> _volunteerEntries = [];
  List<Map<String, dynamic>> _allEntries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAdminEntries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _searchControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchAdminEntries() async {
    setState(() => _loading = true);
    final entries = await _service.getAdminEntries();
    setState(() {
      _entries = entries;
      _volunteerEntries = List<Map<String, dynamic>>.from(entries);
      _allEntries = List<Map<String, dynamic>>.from(entries);
      _loading = false;
    });
    _applyFilters(0);
    _applyFilters(1);
  }

  String _stringValue(dynamic value) {
    if (value == null) return '';
    if (value is Map) {
      return (value['_id'] ??
              value['id'] ??
              value['fullName'] ??
              value['name'] ??
              '')
          .toString();
    }
    return value.toString();
  }

  String _displayVolunteer(Map<String, dynamic> entry) {
    final volunteer = entry['volunteer'];
    if (volunteer is Map) {
      return (volunteer['fullName'] ??
              volunteer['name'] ??
              volunteer['volunteerCode'] ??
              volunteer['code'] ??
              'Unknown')
          .toString();
    }
    return volunteer?.toString() ?? 'Unknown';
  }

  String _displayVolunteerCode(Map<String, dynamic> entry) {
    final volunteer = entry['volunteer'];
    if (volunteer is Map) {
      return (volunteer['volunteerCode'] ??
              volunteer['code'] ??
              volunteer['_id'] ??
              'Unknown')
          .toString();
    }
    return volunteer?.toString() ?? 'Unknown';
  }

  String _displayActivity(Map<String, dynamic> entry) {
    return (entry['activityType'] ?? entry['activity'] ?? '').toString();
  }

  int _displayHoursInt(Map<String, dynamic> entry) {
    final raw = entry['hoursVolunteered'] ?? entry['hours'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  String _hoursBucket(int hours) {
    if (hours <= 0) return '0 hrs';
    if (hours <= 2) return '1-2 hrs';
    if (hours <= 5) return '3-5 hrs';
    if (hours <= 10) return '6-10 hrs';
    return '11+ hrs';
  }

  int _hoursBucketOrder(String bucket) {
    switch (bucket) {
      case '0 hrs':
        return 0;
      case '1-2 hrs':
        return 1;
      case '3-5 hrs':
        return 2;
      case '6-10 hrs':
        return 3;
      case '11+ hrs':
        return 4;
      default:
        return 99;
    }
  }

  String _displayHours(Map<String, dynamic> entry) =>
      _displayHoursInt(entry).toString();

  String _displayDetails(Map<String, dynamic> entry) {
    return (entry['activityDetails'] ?? entry['activityDetail'] ?? '')
        .toString();
  }

  DateTime? _parseCreatedAt(Map<String, dynamic> entry) {
    final raw = entry['createdAt'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  List<Map<String, dynamic>> _getSourceEntries(int tabIndex) {
    return tabIndex == 0 ? _volunteerEntries : _allEntries;
  }

  List<Map<String, dynamic>> _getFilteredEntries(int tabIndex) {
    final search = _searchControllers[tabIndex].text.trim().toLowerCase();
    final selectedActivity = _selectedActivities[tabIndex];
    final selectedHours = _selectedHours[tabIndex];

    return _getSourceEntries(tabIndex).where((entry) {
      final volunteer = _displayVolunteer(entry).toLowerCase();
      final activity = _displayActivity(entry).toLowerCase();
      final details = _displayDetails(entry).toLowerCase();
      final id = _stringValue(entry['_id']).toLowerCase();
      final volunteerId = _stringValue(entry['volunteer']).toLowerCase();
      final hoursValue = _displayHoursInt(entry);

      final matchesSearch =
          search.isEmpty ||
          volunteer.contains(search) ||
          activity.contains(search) ||
          details.contains(search) ||
          id.contains(search) ||
          volunteerId.contains(search) ||
          hoursValue.toString().contains(search);

      final matchesActivity =
          selectedActivity == 'All' ||
          _displayActivity(entry) == selectedActivity;
      final matchesHours =
          selectedHours == 'All' || _hoursBucket(hoursValue) == selectedHours;

      return matchesSearch && matchesActivity && matchesHours;
    }).toList();
  }

  void _applyFilters(int tabIndex) {
    setState(() {
      if (tabIndex == 0) {
        _volunteerEntries = _getFilteredEntries(0);
      } else {
        _allEntries = _getFilteredEntries(1);
      }
    });
  }

  List<DropdownMenuItem<String>> _buildDropdownItems(
    List<String> values, {
    required String emptyLabel,
  }) {
    final unique =
        <String>{'All', ...values.where((v) => v.trim().isNotEmpty)}.toList();
    return unique
        .map(
          (value) => DropdownMenuItem<String>(
            value: value,
            child: Text(
              value == 'All'
                  ? 'All'
                  : value.isEmpty
                  ? emptyLabel
                  : value,
            ),
          ),
        )
        .toList();
  }

  List<Map<String, dynamic>> _entriesForVolunteer(
    String volunteerId,
    List<Map<String, dynamic>> source,
  ) {
    return source
        .where((entry) => _stringValue(entry['volunteer']) == volunteerId)
        .toList();
  }

  List<Map<String, dynamic>> _groupedVolunteerEntries(int tabIndex) {
    final filtered = _getFilteredEntries(tabIndex);
    final byVolunteer = <String, List<Map<String, dynamic>>>{};

    for (final entry in filtered) {
      final volunteerCode = _displayVolunteerCode(entry);
      if (volunteerCode.isEmpty || volunteerCode == 'Unknown') continue;
      byVolunteer.putIfAbsent(volunteerCode, () => []).add(entry);
    }

    final groups =
        byVolunteer.entries.toList()
          ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return groups
        .map(
          (group) => {
            'volunteerCode': group.key,
            'volunteerName': _displayVolunteer(group.value.first),
            'count': group.value.length,
          },
        )
        .toList();
  }

  Future<void> _showVolunteerEntriesSheet({
    required String volunteerName,
    required String volunteerCode,
  }) async {
    final volunteerEntries =
        _entries
            .where((entry) => _displayVolunteerCode(entry) == volunteerCode)
            .toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                volunteerName,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                'Volunteer Code: $volunteerCode',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.gray1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${volunteerEntries.length} entries',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child:
                        volunteerEntries.isEmpty
                            ? Center(
                              child: Text(
                                'No entries found',
                                style: GoogleFonts.poppins(
                                  color: AppColors.gray1,
                                ),
                              ),
                            )
                            : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              itemCount: volunteerEntries.length,
                              itemBuilder:
                                  (context, index) =>
                                      _buildEntryCard(volunteerEntries[index]),
                            ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditDialog(Map<String, dynamic> entry) async {
    final hoursController = TextEditingController(text: _displayHours(entry));
    String activity =
        _displayActivity(entry).isEmpty ? 'Awareness' : _displayActivity(entry);
    final detailController = TextEditingController(
      text: _displayDetails(entry),
    );
    final messenger = ScaffoldMessenger.of(this.context);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 520),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: StatefulBuilder(
              builder: (dialogBodyContext, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Edit Entry',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: hoursController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Hours volunteered',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.primaryBlue,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: activity,
                      items:
                          const [
                                'Awareness',
                                'Event coordination',
                                'Communication',
                                'Field activity',
                              ]
                              .map(
                                (a) => DropdownMenuItem<String>(
                                  value: a,
                                  child: Text(a),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (value) => setDialogState(
                            () => activity = value ?? activity,
                          ),
                      decoration: InputDecoration(
                        labelText: 'Activity type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: detailController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Activity details',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.primaryBlue,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              final hours =
                                  int.tryParse(hoursController.text.trim()) ??
                                  0;
                              final updates = {
                                'hoursVolunteered': hours,
                                'activityType': activity,
                                'activityDetails': detailController.text.trim(),
                              };
                              Navigator.pop(dialogContext);
                              final ok = await _service.adminUpdateEntry(
                                entry['_id'] ?? entry['id'],
                                updates,
                              );
                              if (!mounted) return;
                              if (ok) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Heartbeat entry updated',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                                _fetchAdminEntries();
                              } else {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Update failed',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.save,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Save',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Delete entry?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            content: Text(
              'This will permanently delete the heartbeat entry.',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: AppColors.gray1),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  'Delete',
                  style: GoogleFonts.poppins(
                    color: AppColors.accentOrange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          ),
    );

    final ok = await _service.adminDeleteEntry(entry['_id'] ?? entry['id']);
    if (!mounted) return;
    Navigator.pop(context);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleted'), backgroundColor: Colors.green),
      );
      _fetchAdminEntries();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delete failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFilterPanel(int tabIndex) {
    final source = _getSourceEntries(tabIndex);
    final activityValues =
        source
            .map(_displayActivity)
            .where((v) => v.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final hourValues =
        source
            .map((e) => _hoursBucket(_displayHoursInt(e)))
            .where((v) => v.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort(
            (a, b) => _hoursBucketOrder(a).compareTo(_hoursBucketOrder(b)),
          );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withOpacity(0.08),
            AppColors.secondaryBlue.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.filter_alt_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Filters',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  _searchControllers[tabIndex].clear();
                  setState(() {
                    _selectedActivities[tabIndex] = 'All';
                    _selectedHours[tabIndex] = 'All';
                  });
                  _applyFilters(tabIndex);
                },
                child: Text(
                  'Clear',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchControllers[tabIndex],
            onChanged: (_) => _applyFilters(tabIndex),
            decoration: InputDecoration(
              hintText: 'Search volunteer, activity, id, hours',
              prefixIcon: Icon(Icons.search, color: AppColors.secondaryBlue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryBlue.withOpacity(0.18),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final activityField = DropdownButtonFormField<String>(
                value: _selectedActivities[tabIndex],
                items: _buildDropdownItems(
                  activityValues,
                  emptyLabel: 'Activity',
                ),
                onChanged: (value) {
                  setState(
                    () => _selectedActivities[tabIndex] = value ?? 'All',
                  );
                  _applyFilters(tabIndex);
                },
                decoration: InputDecoration(
                  labelText: 'Activity type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              );

              final hoursField = DropdownButtonFormField<String>(
                value: _selectedHours[tabIndex],
                items: _buildDropdownItems(hourValues, emptyLabel: 'Hours'),
                onChanged: (value) {
                  setState(() => _selectedHours[tabIndex] = value ?? 'All');
                  _applyFilters(tabIndex);
                },
                decoration: InputDecoration(
                  labelText: 'Hours volunteered',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: activityField),
                    const SizedBox(width: 12),
                    Expanded(child: hoursField),
                  ],
                );
              }

              return Column(
                children: [
                  activityField,
                  const SizedBox(height: 12),
                  hoursField,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(Map<String, dynamic> entry) {
    final volunteerName = _displayVolunteer(entry);
    final volunteerCode = _displayVolunteerCode(entry);
    final activity = _displayActivity(entry);
    final hours = _displayHours(entry);
    final details = _displayDetails(entry);
    final createdAt = _parseCreatedAt(entry);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue.withOpacity(0.06), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          volunteerName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$hours hr',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Code: $volunteerCode',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    activity,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (createdAt != null)
                    Text(
                      '${createdAt.toLocal()}'.split('.').first,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.gray1,
                      ),
                    ),
                  if (details.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      details,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.gray2,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _showEditDialog(entry),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: Text(
                          'Edit',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _confirmDelete(entry),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        label: Text(
                          'Delete',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accentOrange,
                        ),
                      ),
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

  Widget _buildTabView(int tabIndex, String title) {
    final filtered = _getFilteredEntries(tabIndex);

    if (tabIndex == 0) {
      final grouped = _groupedVolunteerEntries(tabIndex);

      return RefreshIndicator(
        onRefresh: _fetchAdminEntries,
        child: CustomScrollView(
          key: const PageStorageKey<String>('heartbeat-volunteers-tab'),
          slivers: [
            SliverToBoxAdapter(child: _buildFilterPanel(tabIndex)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${grouped.length}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (grouped.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'No entries',
                    style: GoogleFonts.poppins(color: AppColors.gray1),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final group = grouped[index];
                    final volunteerCode = group['volunteerCode'] as String;
                    final volunteerName = group['volunteerName'] as String;
                    final count = group['count'] as int;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryBlue.withOpacity(0.06),
                            Colors.white,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        onTap:
                            () => _showVolunteerEntriesSheet(
                              volunteerName: volunteerName,
                              volunteerCode: volunteerCode,
                            ),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          volunteerName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        subtitle: Text(
                          'Volunteer Code: $volunteerCode',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.gray1,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$count',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentGreen,
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: grouped.length),
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAdminEntries,
      child: CustomScrollView(
        key: const PageStorageKey<String>('heartbeat-all-tab'),
        slivers: [
          SliverToBoxAdapter(child: _buildFilterPanel(tabIndex)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${filtered.length}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No entries',
                  style: GoogleFonts.poppins(color: AppColors.gray1),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildEntryCard(filtered[index]),
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight1,
      appBar: AppBar(
        title: Text(
          'Heartbeat Helpers',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          tabs: const [Tab(text: 'Volunteers'), Tab(text: 'All Entries')],
        ),
      ),
      body:
          _loading
              ? Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildTabView(0, 'Volunteer Entries'),
                  _buildTabView(1, 'All Entries'),
                ],
              ),
    );
  }
}
