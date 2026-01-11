import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/vms_dashboard_model.dart';
import '../../models/volunteer_model.dart';
import '../../services/vms_service.dart';
import '../../widgets/dashboard_stat_card.dart';
import '../../widgets/status_dropdowns.dart';
import '../../widgets/vms_volunteer_card.dart';

/// VMS Dashboard Screen showing statistics and volunteer overview
class VMSDashboardScreen extends StatefulWidget {
  const VMSDashboardScreen({super.key});

  @override
  State<VMSDashboardScreen> createState() => _VMSDashboardScreenState();
}

class _VMSDashboardScreenState extends State<VMSDashboardScreen> {
  final VMSService _vmsService = VMSService();
  
  bool _isLoading = true;
  VMSDashboardStats? _stats;
  List<Volunteer> _volunteers = [];
  VolunteerStage? _selectedStage;
  String _searchQuery = '';
  String? _error;

  // Theme colors
  static const primaryColor = Color(0xFF1E88E5);
  static const backgroundColor = Color(0xFFF8FFFE);
  static const textPrimary = Color(0xFF2C3E50);
  static const textSecondary = Color(0xFF7F8C8D);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load dashboard stats and volunteers in parallel
      final statsResponse = await _vmsService.getDashboard();
      final volunteersResponse = await _vmsService.getAllVolunteers();

      setState(() {
        if (statsResponse.isSuccess) {
          _stats = statsResponse.data;
        } else {
          _error = statsResponse.error;
        }

        if (volunteersResponse.isSuccess) {
          _volunteers = volunteersResponse.data ?? [];
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadVolunteersByStage(VolunteerStage? stage) async {
    setState(() => _isLoading = true);

    try {
      final response = stage != null
          ? await _vmsService.getVolunteersByStage(stage.value)
          : await _vmsService.getAllVolunteers();

      setState(() {
        if (response.isSuccess) {
          _volunteers = response.data ?? [];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Volunteer> get _filteredVolunteers {
    var filtered = _volunteers;

    // Filter by stage
    if (_selectedStage != null) {
      filtered = filtered.where((v) => v.currentStage == _selectedStage).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((v) {
        return v.displayName.toLowerCase().contains(query) ||
            (v.volunteerCode?.toLowerCase().contains(query) ?? false) ||
            (v.email?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _navigateToVolunteerDetail(Volunteer volunteer) {
    Navigator.pushNamed(
      context,
      '/admin/vms/volunteer/${volunteer.id}',
      arguments: volunteer,
    );
  }

  void _navigateToCertificates() {
    Navigator.pushNamed(context, '/admin/vms/certificates');
  }

  Future<void> _exportCSV() async {
    final response = await _vmsService.exportCSV(
      stage: _selectedStage?.value,
    );

    if (response.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Text('CSV export started'),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      _showError(response.error ?? 'Failed to export CSV');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(
          'VMS Dashboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium_rounded, color: Colors.white),
            onPressed: _navigateToCertificates,
            tooltip: 'Certificate Management',
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: _exportCSV,
            tooltip: 'Export CSV',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    slivers: [
                      // Stats Grid
                      SliverToBoxAdapter(
                        child: _buildStatsSection(),
                      ),

                      // Search and Filter
                      SliverToBoxAdapter(
                        child: _buildSearchAndFilter(),
                      ),

                      // Volunteers List
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: _filteredVolunteers.isEmpty
                            ? SliverToBoxAdapter(child: _buildEmptyState())
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final volunteer = _filteredVolunteers[index];
                                    return VMSVolunteerCard(
                                      volunteer: volunteer,
                                      onTap: () => _navigateToVolunteerDetail(volunteer),
                                    );
                                  },
                                  childCount: _filteredVolunteers.length,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error Loading Data',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_stats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              DashboardStatCard(
                title: 'Total Volunteers',
                value: _stats!.totalVolunteers,
                icon: Icons.people_rounded,
                color: primaryColor,
                onTap: () {
                  setState(() => _selectedStage = null);
                },
              ),
              DashboardStatCard(
                title: 'Pending Approval',
                value: _stats!.pendingApproval,
                icon: Icons.pending_actions_rounded,
                color: Colors.orange,
              ),
              DashboardStatCard(
                title: 'In Onboarding',
                value: _stats!.inOnboarding,
                icon: Icons.person_add_rounded,
                color: Colors.purple,
                onTap: () {
                  setState(() => _selectedStage = VolunteerStage.onboarding);
                  _loadVolunteersByStage(VolunteerStage.onboarding);
                },
              ),
              DashboardStatCard(
                title: 'In Training',
                value: _stats!.inTraining,
                icon: Icons.school_rounded,
                color: Colors.blue,
                onTap: () {
                  setState(() => _selectedStage = VolunteerStage.training);
                  _loadVolunteersByStage(VolunteerStage.training);
                },
              ),
              DashboardStatCard(
                title: 'Active Mentoring',
                value: _stats!.activeMentoring,
                icon: Icons.groups_rounded,
                color: Colors.teal,
                onTap: () {
                  setState(() => _selectedStage = VolunteerStage.mentoring);
                  _loadVolunteersByStage(VolunteerStage.mentoring);
                },
              ),
              DashboardStatCard(
                title: 'Exit Pending',
                value: _stats!.exitPending,
                icon: Icons.logout_rounded,
                color: Colors.red,
                onTap: () {
                  setState(() => _selectedStage = VolunteerStage.exitPending);
                  _loadVolunteersByStage(VolunteerStage.exitPending);
                },
              ),
              DashboardStatCard(
                title: 'Certificate Eligible',
                value: _stats!.certificateEligible,
                icon: Icons.workspace_premium_rounded,
                color: Colors.amber[700]!,
                onTap: _navigateToCertificates,
              ),
              DashboardStatCard(
                title: 'Certificates Issued',
                value: _stats!.certificateIssued,
                icon: Icons.card_membership_rounded,
                color: Colors.green,
                onTap: _navigateToCertificates,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by name, code (TSF-2025-XXXX), or email...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: textSecondary,
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: primaryColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Stage filter
          StageFilterDropdown(
            value: _selectedStage,
            onChanged: (stage) {
              setState(() => _selectedStage = stage);
              _loadVolunteersByStage(stage);
            },
          ),
          const SizedBox(height: 8),
          
          // Results count
          Text(
            '${_filteredVolunteers.length} volunteer${_filteredVolunteers.length == 1 ? '' : 's'} found',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No volunteers found',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'No volunteers in this category',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
