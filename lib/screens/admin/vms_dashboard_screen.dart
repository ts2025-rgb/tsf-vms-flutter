import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/vms_dashboard_model.dart';
import '../../models/volunteer_model.dart';
import '../../services/vms_service.dart';
import '../../widgets/dashboard_stat_card.dart';
import '../../widgets/status_dropdowns.dart';
import '../../widgets/vms_volunteer_card.dart';
import '../../config/app_colors.dart';
import 'ccp_controls_screen.dart';
import 'enhanced_vms_dashboard_screen.dart';

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

  // Theme colors (using AppColors)
  static final primaryColor = AppColors.primaryBlue;
  static final backgroundColor = AppColors.backgroundLight1;
  static final textPrimary = AppColors.textDark;
  static final textSecondary = AppColors.gray1;

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
      final response =
          stage != null
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
      filtered =
          filtered.where((v) => v.currentStage == _selectedStage).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered =
          filtered.where((v) {
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

  void _navigateToCCPControls() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CCPControlsScreen()),
    );
  }

  void _navigateToEnhancedDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EnhancedVMSDashboardScreen(),
      ),
    );
  }

  Future<void> _exportCSV() async {
    final response = await _vmsService.exportCSV(stage: _selectedStage?.value);

    if (response.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              const Text('CSV export started'),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
          // Enhanced Metrics Dashboard
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.analytics_rounded, color: Colors.white),
              onPressed: _navigateToEnhancedDashboard,
              tooltip: 'Enhanced Metrics Dashboard',
            ),
          ),
          // CCP Controls - Combined Mentee & Query Management
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.settings_suggest_rounded,
                color: Colors.white,
              ),
              onPressed: _navigateToCCPControls,
              tooltip: 'CCP Controls (Mentee & Query Management)',
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
            ),
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
          const SizedBox(width: 8),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    // Stats Grid
                    SliverToBoxAdapter(child: _buildStatsSection()),

                    // Search and Filter
                    SliverToBoxAdapter(child: _buildSearchAndFilter()),

                    // Volunteers List
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver:
                          _filteredVolunteers.isEmpty
                              ? SliverToBoxAdapter(child: _buildEmptyState())
                              : SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final volunteer = _filteredVolunteers[index];
                                  return VMSVolunteerCard(
                                    volunteer: volunteer,
                                    onTap:
                                        () => _navigateToVolunteerDetail(
                                          volunteer,
                                        ),
                                  );
                                }, childCount: _filteredVolunteers.length),
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
            style: GoogleFonts.poppins(fontSize: 14, color: textSecondary),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dashboard Overview',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people_rounded, color: primaryColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${_stats!.totalVolunteers} Total',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Key Metrics - Highlighted
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildHighlightStat(
                    'Active Mentoring',
                    _stats!.activeMentoring,
                    Icons.groups_rounded,
                    () {
                      setState(() => _selectedStage = VolunteerStage.mentoring);
                      _loadVolunteersByStage(VolunteerStage.mentoring);
                    },
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildHighlightStat(
                    'Pending Approval',
                    _stats!.pendingApproval,
                    Icons.pending_actions_rounded,
                    null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stage Breakdown Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
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
                title: 'Certificate Ready',
                value: _stats!.certificateEligible,
                icon: Icons.workspace_premium_rounded,
                color: Colors.amber[700]!,
                onTap: _navigateToCertificates,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightStat(
    String title,
    int value,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
                hintText: 'Search by name, code (PY4P-2025-XXXX), or email...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: textSecondary,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: primaryColor,
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
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
            style: GoogleFonts.poppins(fontSize: 12, color: textSecondary),
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
            style: GoogleFonts.poppins(fontSize: 14, color: textSecondary),
          ),
        ],
      ),
    );
  }
}
