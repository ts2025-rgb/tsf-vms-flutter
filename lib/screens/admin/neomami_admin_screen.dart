import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:any_link_preview/any_link_preview.dart';
import '../../config/api_config.dart';
import '../../config/app_colors.dart';
import '../../models/neomami_model.dart';
import '../../services/neomami_service.dart';

class NeomamAdminScreen extends StatefulWidget {
  const NeomamAdminScreen({super.key});

  @override
  State<NeomamAdminScreen> createState() => _NeomamAdminScreenState();
}

class _NeomamAdminScreenState extends State<NeomamAdminScreen>
    with SingleTickerProviderStateMixin {
  final String baseUrl = ApiConfig.apiUrl;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final NeomamService _neomamService = NeomamService();

  late TabController _tabController;

  // Volunteers view
  List<dynamic> _volunteers = [];
  bool _volunteersLoading = true;
  String? _volunteersError;
  String _volunteerSearch = '';
  String _volunteerSort = 'entryCount';
  dynamic _selectedVolunteer;
  List<dynamic> _selectedVolunteerEntries = [];
  bool _selectedVolunteerEntriesLoading = false;

  // All entries view
  List<dynamic> _allEntries = [];
  bool _entriesLoading = true;
  String? _entriesError;
  String _entriesSearch = '';
  String _entriesSort = 'latest';
  String _filterVolunteerId = '';
  int _currentPage = 1;
  int _totalPages = 1;

  String? _adminToken;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAdminTokenAndFetch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminTokenAndFetch() async {
    await _loadAdminToken();
    await _fetchVolunteers();
    await _fetchFilteredEntries();
  }

  Future<void> _loadAdminToken() async {
    try {
      final data = await secureStorage.read(key: "adminToken");
      if (data != null) {
        setState(() {
          _adminToken = data;
        });
      }
    } catch (e) {
      print('Error loading admin token: $e');
    }
  }

  Future<void> _fetchVolunteers() async {
    setState(() {
      _volunteersLoading = true;
      _volunteersError = null;
    });

    final result = await _neomamService.getVolunteersWithEntryCounts(
      search: _volunteerSearch.isEmpty ? null : _volunteerSearch,
      sortBy: _volunteerSort,
    );

    if (mounted) {
      setState(() {
        _volunteersLoading = false;
        if (result['success']) {
          _volunteers = result['volunteers'] ?? [];
          _volunteersError = null;
        } else {
          _volunteers = [];
          _volunteersError = result['message'];
        }
      });
    }
  }

  Future<void> _fetchVolunteerEntries(String volunteerId) async {
    setState(() {
      _selectedVolunteerEntriesLoading = true;
    });

    final result = await _neomamService.getVolunteerEntries(volunteerId);

    if (mounted) {
      setState(() {
        _selectedVolunteerEntriesLoading = false;
        if (result['success']) {
          _selectedVolunteer = result['volunteer'];
          _selectedVolunteerEntries = result['entries'] ?? [];
        } else {
          _selectedVolunteer = null;
          _selectedVolunteerEntries = [];
        }
      });
    }
  }

  Future<void> _fetchFilteredEntries() async {
    setState(() {
      _entriesLoading = true;
      _entriesError = null;
    });

    final result = await _neomamService.getFilteredEntries(
      volunteerId: _filterVolunteerId.isEmpty ? null : _filterVolunteerId,
      search: _entriesSearch.isEmpty ? null : _entriesSearch,
      sortBy: _entriesSort,
      page: _currentPage,
      limit: 10,
    );

    if (mounted) {
      setState(() {
        _entriesLoading = false;
        if (result['success']) {
          _allEntries = result['entries'] ?? [];
          _totalPages = result['pages'] ?? 1;
          _entriesError = null;
        } else {
          _allEntries = [];
          _entriesError = result['message'];
        }
      });
    }
  }

  void _showEditDialog(dynamic entry) {
    showDialog(
      context: context,
      builder:
          (context) => _AdminEditEntryDialog(
            entry: entry,
            onSave: (updatedEntry) {
              _updateEntry(entry['_id'] ?? entry['id'], updatedEntry);
            },
          ),
    );
  }

  void _confirmDelete(dynamic entry) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Delete Entry?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: Text(
              'Are you sure you want to delete this entry? This action cannot be undone.',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteEntry(entry['_id'] ?? entry['id']);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Delete', style: GoogleFonts.poppins()),
              ),
            ],
          ),
    );
  }

  Map<String, dynamic>? _getSocialMediaInfo(String url) {
    // Check for various social media platforms
    if (url.contains('instagram.com')) {
      return {
        'platform': 'Instagram',
        'icon': Icons.camera_alt,
        'color': const Color(0xFFE4405F),
      };
    } else if (url.contains('tiktok.com')) {
      return {
        'platform': 'TikTok',
        'icon': Icons.play_circle_fill,
        'color': const Color(0xFF000000),
      };
    } else if (url.contains('twitter.com') || url.contains('x.com')) {
      return {
        'platform': 'X (Twitter)',
        'icon': Icons.share,
        'color': const Color(0xFF000000),
      };
    } else if (url.contains('facebook.com')) {
      return {
        'platform': 'Facebook',
        'icon': Icons.people,
        'color': const Color(0xFF1877F2),
      };
    } else if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return {
        'platform': 'YouTube',
        'icon': Icons.play_circle,
        'color': const Color(0xFFFF0000),
      };
    } else if (url.contains('linkedin.com')) {
      return {
        'platform': 'LinkedIn',
        'icon': Icons.work,
        'color': const Color(0xFF0A66C2),
      };
    } else if (url.contains('github.com')) {
      return {
        'platform': 'GitHub',
        'icon': Icons.code,
        'color': const Color(0xFF333333),
      };
    } else if (url.contains('medium.com')) {
      return {
        'platform': 'Medium',
        'icon': Icons.article,
        'color': const Color(0xFF000000),
      };
    }
    return null;
  }

  Widget _buildSocialMediaPreview(String url, Map<String, dynamic> info) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (info['color'] as Color).withOpacity(0.3),
          width: 2,
        ),
        gradient: LinearGradient(
          colors: [
            (info['color'] as Color).withOpacity(0.05),
            (info['color'] as Color).withOpacity(0.02),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (info['color'] as Color).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              info['icon'] as IconData,
              color: info['color'] as Color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info['platform'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: info['color'] as Color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Click to open',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.open_in_new,
            size: 16,
            color: (info['color'] as Color).withOpacity(0.6),
          ),
        ],
      ),
    );
  }

  void _openLink(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Link is empty', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Ensure URL has proper scheme
    String urlToOpen = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      urlToOpen = 'https://$url';
    }

    try {
      // Try to open URL in browser/new tab
      if (await canLaunchUrl(Uri.parse(urlToOpen))) {
        await launchUrl(
          Uri.parse(urlToOpen),
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Neomami Hub - Admin View',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.7),
          ),
          tabs: [
            Tab(
              text: 'Volunteers',
              icon: const Icon(Icons.people, color: Colors.white),
            ),
            Tab(
              text: 'All Entries',
              icon: const Icon(Icons.description, color: Colors.white),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildVolunteersView(), _buildAllEntriesView()],
      ),
    );
  }

  Widget _buildVolunteersView() {
    if (_volunteersLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryBlue),
            const SizedBox(height: 16),
            Text(
              'Loading volunteers...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (_volunteersError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _volunteersError!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchVolunteers,
              icon: const Icon(Icons.refresh),
              label: Text('Retry', style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search and Filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                onChanged: (value) {
                  setState(() => _volunteerSearch = value);
                  _fetchVolunteers();
                },
                decoration: InputDecoration(
                  hintText: 'Search by name, code, or email...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                isExpanded: true,
                value: _volunteerSort,
                items: [
                  DropdownMenuItem(
                    value: 'entryCount',
                    child: Text(
                      'Sort by: Entry Count',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'name',
                    child: Text('Sort by: Name', style: GoogleFonts.poppins()),
                  ),
                  DropdownMenuItem(
                    value: 'latest',
                    child: Text(
                      'Sort by: Latest Entry',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _volunteerSort = value ?? 'entryCount');
                  _fetchVolunteers();
                },
              ),
            ],
          ),
        ),
        // Volunteers List or Selected Volunteer Entries
        Expanded(
          child:
              _selectedVolunteer == null
                  ? _buildVolunteersList()
                  : _buildSelectedVolunteerEntries(),
        ),
      ],
    );
  }

  Widget _buildVolunteersList() {
    if (_volunteers.isEmpty) {
      return Center(
        child: Text(
          'No volunteers found',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _volunteers.length,
      itemBuilder: (context, index) {
        final volunteer = _volunteers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              volunteer['fullName'] ?? 'Unknown',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              volunteer['volunteerCode'] ?? '',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${volunteer['entryCount'] ?? 0} entries',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentGreen,
                ),
              ),
            ),
            onTap: () => _fetchVolunteerEntries(volunteer['_id']),
          ),
        );
      },
    );
  }

  Widget _buildSelectedVolunteerEntries() {
    if (_selectedVolunteerEntriesLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryBlue.withOpacity(0.1),
                AppColors.secondaryBlue.withOpacity(0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedVolunteer = null),
                color: AppColors.primaryBlue,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedVolunteer['fullName'] ?? 'Unknown',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    Text(
                      _selectedVolunteer['volunteerCode'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedVolunteerEntries.length} entries',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _selectedVolunteerEntries.isEmpty
                  ? Center(
                    child: Text(
                      'No entries for this volunteer',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _selectedVolunteerEntries.length,
                    itemBuilder: (context, index) {
                      final entry = _selectedVolunteerEntries[index];
                      return _buildEntryCard(
                        entry,
                        onEdit: () => _showEditDialog(entry),
                        onDelete: () => _confirmDelete(entry),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildAllEntriesView() {
    return Column(
      children: [
        // Search and Filters
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                onChanged: (value) {
                  setState(() {
                    _entriesSearch = value;
                    _currentPage = 1;
                  });
                  _fetchFilteredEntries();
                },
                decoration: InputDecoration(
                  hintText: 'Search entries...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _entriesSort,
                      items: [
                        DropdownMenuItem(
                          value: 'latest',
                          child: Text('Latest', style: GoogleFonts.poppins()),
                        ),
                        DropdownMenuItem(
                          value: 'oldest',
                          child: Text('Oldest', style: GoogleFonts.poppins()),
                        ),
                        DropdownMenuItem(
                          value: 'hours',
                          child: Text(
                            'Hours (High)',
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'title',
                          child: Text(
                            'Title A-Z',
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _entriesSort = value ?? 'latest';
                          _currentPage = 1;
                        });
                        _fetchFilteredEntries();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Entries List
        if (_entriesError != null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _entriesError!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_entriesLoading)
          Expanded(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            ),
          )
        else if (_allEntries.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No entries found',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _allEntries.length,
              itemBuilder: (context, index) {
                final entry = _allEntries[index];
                return _buildEntryCard(
                  entry,
                  onEdit: () => _showEditDialog(entry),
                  onDelete: () => _confirmDelete(entry),
                );
              },
            ),
          ),
        // Pagination
        if (_totalPages > 1)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed:
                      _currentPage > 1
                          ? () {
                            setState(() => _currentPage--);
                            _fetchFilteredEntries();
                          }
                          : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                ),
                const SizedBox(width: 16),
                Text(
                  'Page $_currentPage of $_totalPages',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed:
                      _currentPage < _totalPages
                          ? () {
                            setState(() => _currentPage++);
                            _fetchFilteredEntries();
                          }
                          : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _updateEntry(String entryId, dynamic updatedEntry) async {
    final neomamEntry = NeomamEntry(
      volunteerId: updatedEntry['volunteerId'] ?? '',
      title: updatedEntry['title'],
      description: updatedEntry['description'],
      hoursDedicated: updatedEntry['hoursDedicated'],
      skillsLearned: updatedEntry['skillsLearned'],
      linkOfWork: updatedEntry['linkOfWork'],
    );

    final result = await _neomamService.adminUpdateNeomamEntry(
      entryId,
      neomamEntry,
    );

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppColors.accentGreen,
          ),
        );
        if (_selectedVolunteer != null) {
          await _fetchVolunteerEntries(_selectedVolunteer['_id']);
        } else {
          await _fetchFilteredEntries();
        }
        await _fetchVolunteers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteEntry(String entryId) async {
    final result = await _neomamService.adminDeleteNeomamEntry(entryId);

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppColors.accentGreen,
          ),
        );
        if (_selectedVolunteer != null) {
          await _fetchVolunteerEntries(_selectedVolunteer['_id']);
        } else {
          await _fetchFilteredEntries();
        }
        await _fetchVolunteers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(
    dynamic entry, {
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    // Map API field names to display field names
    final title = entry['contentPostedTitle'] ?? entry['title'] ?? 'Untitled';
    final description =
        entry['contentPostedDescription'] ?? entry['description'] ?? '';
    final hours = entry['hoursDedicated'] ?? 0;
    final skills = entry['newSkillsLearned'] ?? entry['skillsLearned'] ?? '';
    final linkOfWork = entry['linkOfWork'];

    // Get volunteer name - either from nested volunteer object or selected volunteer
    String volunteerName = 'Unknown Volunteer';
    if (entry['volunteer'] != null && entry['volunteer'] is Map) {
      volunteerName = entry['volunteer']['fullName'] ?? 'Unknown Volunteer';
    } else if (entry['volunteerName'] != null) {
      volunteerName = entry['volunteerName'];
    } else if (_selectedVolunteer != null) {
      volunteerName = _selectedVolunteer['fullName'] ?? 'Unknown Volunteer';
    }

    final createdAt =
        entry['createdAt'] != null
            ? '${DateTime.parse(entry['createdAt'].toString()).month}/${DateTime.parse(entry['createdAt'].toString()).day}/${DateTime.parse(entry['createdAt'].toString()).year}'
            : 'No date';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryBlue.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withOpacity(0.08),
                    AppColors.secondaryBlue.withOpacity(0.04),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryBlue,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'By: $volunteerName',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          createdAt,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  _buildInfoSection(
                    icon: Icons.description,
                    label: 'Description',
                    content: description,
                  ),
                  const SizedBox(height: 12),
                  // Hours
                  _buildInfoSection(
                    icon: Icons.access_time,
                    label: 'Hours Dedicated',
                    content: '$hours hours',
                  ),
                  const SizedBox(height: 12),
                  // Skills
                  _buildInfoSection(
                    icon: Icons.school,
                    label: 'Skills Learned',
                    content: skills,
                  ),
                  if (linkOfWork != null &&
                      linkOfWork.toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    // Link of Work
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.link,
                              size: 16,
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Link of Work',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            _openLink(linkOfWork.toString());
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child:
                                _getSocialMediaInfo(linkOfWork.toString()) !=
                                        null
                                    ? _buildSocialMediaPreview(
                                      linkOfWork.toString(),
                                      _getSocialMediaInfo(
                                        linkOfWork.toString(),
                                      )!,
                                    )
                                    : Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: AppColors.primaryBlue
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: AnyLinkPreview(
                                        link: linkOfWork.toString(),
                                        displayDirection:
                                            UIDirection.uiDirectionHorizontal,
                                        cache: const Duration(hours: 1),
                                        backgroundColor: Colors.white,
                                        borderRadius: 0,
                                        titleStyle: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        bodyStyle: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                        ),
                                        errorBody: 'Unable to load preview',
                                        errorTitle: 'Link Preview',
                                        errorWidget: Container(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.link,
                                                size: 32,
                                                color: AppColors.primaryBlue,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Open Link',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primaryBlue,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                linkOfWork.toString(),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        onTap: () {
                                          _openLink(linkOfWork.toString());
                                        },
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text('Edit', style: GoogleFonts.poppins()),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 18),
                    label: Text('Delete', style: GoogleFonts.poppins()),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String label,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade800,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Dialog for editing an entry by admin
class _AdminEditEntryDialog extends StatefulWidget {
  final dynamic entry;
  final Function(dynamic) onSave;

  const _AdminEditEntryDialog({required this.entry, required this.onSave});

  @override
  State<_AdminEditEntryDialog> createState() => _AdminEditEntryDialogState();
}

class _AdminEditEntryDialogState extends State<_AdminEditEntryDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _hoursController;
  late final TextEditingController _skillsController;
  late final TextEditingController _linkController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text:
          widget.entry['contentPostedTitle'] ??
          widget.entry['title'] ??
          'Untitled',
    );
    _descriptionController = TextEditingController(
      text:
          widget.entry['contentPostedDescription'] ??
          widget.entry['description'] ??
          '',
    );
    _hoursController = TextEditingController(
      text: widget.entry['hoursDedicated']?.toString() ?? '0',
    );
    _skillsController = TextEditingController(
      text:
          widget.entry['newSkillsLearned'] ??
          widget.entry['skillsLearned'] ??
          '',
    );
    _linkController = TextEditingController(
      text: widget.entry['linkOfWork'] ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hoursController.dispose();
    _skillsController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _hoursController.text.isEmpty ||
        _skillsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill all required fields',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate URL if provided
    if (_linkController.text.isNotEmpty) {
      if (!_isValidUrl(_linkController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enter a valid URL',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final updatedEntry = {
      'volunteerId': widget.entry['volunteerId'] ?? '',
      'title': _titleController.text,
      'description': _descriptionController.text,
      'hoursDedicated': int.tryParse(_hoursController.text) ?? 0,
      'skillsLearned': _skillsController.text,
      'linkOfWork': _linkController.text.isEmpty ? null : _linkController.text,
    };

    widget.onSave(updatedEntry);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Entry',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStyledTextField(
                      controller: _titleController,
                      label: 'Title',
                      icon: Icons.title,
                      hint: 'Enter entry title',
                    ),
                    const SizedBox(height: 16),
                    _buildStyledTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      icon: Icons.description,
                      hint: 'Enter detailed description',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildStyledTextField(
                      controller: _hoursController,
                      label: 'Hours Dedicated',
                      icon: Icons.access_time,
                      hint: 'Enter hours (number)',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildStyledTextField(
                      controller: _skillsController,
                      label: 'Skills Learned',
                      icon: Icons.school,
                      hint: 'Enter skills acquired',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _buildStyledTextField(
                      controller: _linkController,
                      label: 'Link of Work (Optional)',
                      icon: Icons.link,
                      hint: 'Enter URL (https://...)',
                    ),
                  ],
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: Text(
                      'Update',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade400,
            ),
            filled: true,
            fillColor: AppColors.primaryBlue.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primaryBlue.withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primaryBlue.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

bool _isValidUrl(String url) {
  try {
    Uri.parse(url);
    return url.startsWith('http://') || url.startsWith('https://');
  } catch (e) {
    return false;
  }
}
