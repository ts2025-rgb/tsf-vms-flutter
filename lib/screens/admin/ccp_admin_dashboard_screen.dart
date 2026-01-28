import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/api_config.dart';
import '../../config/app_colors.dart';

class CCPAdminDashboardScreen extends StatefulWidget {
  const CCPAdminDashboardScreen({super.key});

  @override
  State<CCPAdminDashboardScreen> createState() => _CCPAdminDashboardScreenState();
}

class _CCPAdminDashboardScreenState extends State<CCPAdminDashboardScreen> {
  final String baseUrl = ApiConfig.apiUrl;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  List<dynamic> _volunteers = [];
  List<dynamic> _mentees = [];
  List<dynamic> _queries = [];
  
  // Metrics
  int _totalVolunteers = 0;
  int _activeVolunteers = 0;
  int _totalMentees = 0;
  int _assignedMentees = 0;
  int _unassignedMentees = 0;
  int _pendingQueries = 0;
  int _totalCallHours = 0;
  double _avgCallDuration = 0;
  
  // Lifecycle breakdown
  Map<String, int> _lifecycleBreakdown = {};
  
  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }
  
  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await secureStorage.read(key: "adminToken");
      
      if (token == null) {
        _showError("Authentication token not found. Please login again.");
        return;
      }
      
      // Fetch all data in parallel
      await Future.wait([
        _fetchVolunteers(token),
        _fetchMentees(token),
        _fetchQueries(token),
      ]);
      
      // Calculate metrics
      _calculateMetrics();
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error fetching dashboard data: $e');
      setState(() => _isLoading = false);
      _showError("Error loading dashboard data");
    }
  }
  
  Future<void> _fetchVolunteers(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/volunteers'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _volunteers = data['volunteers'] ?? [];
        }
      }
    } catch (e) {
      print('Error fetching volunteers: $e');
    }
  }
  
  Future<void> _fetchMentees(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/companion-connect/admin/mentees'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _mentees = data['mentees'] ?? [];
        }
      }
    } catch (e) {
      print('Error fetching mentees: $e');
    }
  }
  
  Future<void> _fetchQueries(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/companion-connect/admin/queries'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _queries = data['queries'] ?? [];
        }
      }
    } catch (e) {
      print('Error fetching queries: $e');
    }
  }
  
  void _calculateMetrics() {
    // Filter volunteers for Companion Connect program
    final ccVolunteers = _volunteers.where((v) {
      final programs = v['interestedPrograms'] as List?;
      if (programs == null) return false;
      
      return programs.any((p) {
        // Handle both String (program ID) and Map (program object)
        if (p is String) {
          return p.toLowerCase().contains('companion connect') || 
                 p == '6965d79f30cff35de1a08f79'; // Companion Connect ID
        } else if (p is Map) {
          final name = p['name']?.toString() ?? '';
          return name.toLowerCase().contains('companion connect');
        }
        return false;
      });
    }).toList();
    
    _totalVolunteers = ccVolunteers.length;
    _activeVolunteers = ccVolunteers.where((v) => 
      v['mentoringStatus'] == 'active' && v['approvalStatus'] == 'approved'
    ).length;
    
    _totalMentees = _mentees.length;
    _assignedMentees = _mentees.where((m) => m['assignedTo'] != null).length;
    _unassignedMentees = _totalMentees - _assignedMentees;
    
    _pendingQueries = _queries.where((q) => q['status'] == 'pending').length;
    
    // Calculate call statistics
    int totalCalls = 0;
    double totalHours = 0;
    int volunteerCount = 0;
    
    for (var volunteer in ccVolunteers) {
      final callStats = volunteer['callStats'];
      if (callStats != null) {
        totalCalls += (callStats['totalCalls'] as int?) ?? 0;
        totalHours += (callStats['totalCallHours'] as num?)?.toDouble() ?? 0;
        if (callStats['totalCalls'] != null && callStats['totalCalls'] > 0) {
          volunteerCount++;
        }
      }
    }
    
    _totalCallHours = totalHours.round();
    _avgCallDuration = totalCalls > 0 ? (totalHours * 60) / totalCalls : 0;
    
    // Lifecycle breakdown
    _lifecycleBreakdown = {
      'Onboarding': ccVolunteers.where((v) => v['onboardingStatus'] == 'in_progress').length,
      'Training': ccVolunteers.where((v) => v['trainingStatus'] == 'in_progress').length,
      'Active': ccVolunteers.where((v) => v['mentoringStatus'] == 'active').length,
      'Exit Pending': ccVolunteers.where((v) => v['exitStatus'] == 'exit_requested' || v['exitStatus'] == 'handover_pending').length,
      'Completed': ccVolunteers.where((v) => v['exitStatus'] == 'exited').length,
    };
  }
  
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        foregroundColor: Colors.white,
        title: Text(
          "Companion Connect Analytics",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchDashboardData,
            tooltip: "Refresh Data",
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Metrics
                    _buildOverviewSection(),
                    
                    SizedBox(height: 24),
                    
                    // Call Statistics
                    _buildCallStatisticsSection(),
                    
                    SizedBox(height: 24),
                    
                    // Lifecycle Breakdown
                    _buildLifecycleSection(),
                    
                    SizedBox(height: 24),
                    
                    // Mentee Assignment Status
                    _buildMenteeAssignmentSection(),
                    
                    SizedBox(height: 24),
                    
                    // Top Performers Chart
                    _buildTopPerformersSection(),
                    
                    SizedBox(height: 24),
                    
                    // Recent Queries
                    _buildQueriesSection(),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Program Overview",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.dark2,
          ),
        ),
        SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              "Total Volunteers",
              _totalVolunteers.toString(),
              Icons.people,
              AppColors.primaryBlue,
            ),
            _buildMetricCard(
              "Active Volunteers",
              _activeVolunteers.toString(),
              Icons.verified_user,
              AppColors.accentGreen,
            ),
            _buildMetricCard(
              "Total Mentees",
              _totalMentees.toString(),
              Icons.school,
              AppColors.accentOrange,
            ),
            _buildMetricCard(
              "Pending Queries",
              _pendingQueries.toString(),
              Icons.help_outline,
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCallStatisticsSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_in_talk, color: AppColors.primaryBlue),
              SizedBox(width: 8),
              Text(
                "Call Statistics",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  "Total Hours",
                  "$_totalCallHours hrs",
                  Icons.access_time,
                  AppColors.accentGreen,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  "Avg Duration",
                  "${_avgCallDuration.toStringAsFixed(1)} min",
                  Icons.timer,
                  AppColors.accentOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLifecycleSection() {
    final hasData = _lifecycleBreakdown.values.any((v) => v > 0);
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: AppColors.primaryBlue),
              SizedBox(width: 8),
              Text(
                "Volunteer Lifecycle",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          if (hasData) ...[
            // Simple visual representation instead of complex pie chart
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _lifecycleBreakdown.entries.map((entry) {
                  return Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _getLifecycleColor(entry.key),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.value}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        entry.key,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 20),
          ],
          // Progress bars
          ..._lifecycleBreakdown.entries.map((entry) {
            final total = _totalVolunteers > 0 ? _totalVolunteers : 1;
            final percentage = (entry.value / total * 100).toStringAsFixed(0);
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getLifecycleColor(entry.key),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            entry.key,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "${entry.value} ($percentage%)",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: entry.value / total,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getLifecycleColor(entry.key),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Color _getLifecycleColor(String stage) {
    switch (stage) {
      case 'Onboarding':
        return Colors.blue;
      case 'Training':
        return Colors.purple;
      case 'Active':
        return AppColors.accentGreen;
      case 'Exit Pending':
        return Colors.orange;
      case 'Completed':
        return Colors.grey;
      default:
        return AppColors.primaryBlue;
    }
  }
  
  Widget _buildMenteeAssignmentSection() {
    final assignmentPercentage = _totalMentees > 0 
        ? (_assignedMentees / _totalMentees * 100).toStringAsFixed(0)
        : "0";
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withOpacity(0.1),
            AppColors.accentGreen.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, color: AppColors.primaryBlue),
              SizedBox(width: 8),
              Text(
                "Mentee Assignments",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _assignedMentees.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGreen,
                      ),
                    ),
                    Text(
                      "Assigned",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 50,
                width: 1,
                color: Colors.grey.shade300,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _unassignedMentees.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      "Unassigned",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Center(
            child: Text(
              "$assignmentPercentage% Assignment Rate",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopPerformersSection() {
    // Get top volunteers by call hours
    final ccVolunteers = _volunteers.where((v) {
      final programs = v['interestedPrograms'] as List?;
      if (programs == null) return false;
      
      return programs.any((p) {
        // Handle both String (program ID) and Map (program object)
        if (p is String) {
          return p.toLowerCase().contains('companion connect') || 
                 p == '6965d79f30cff35de1a08f79'; // Companion Connect ID
        } else if (p is Map) {
          final name = p['name']?.toString() ?? '';
          return name.toLowerCase().contains('companion connect');
        }
        return false;
      });
    }).toList();
    
    // Sort by total call hours
    ccVolunteers.sort((a, b) {
      final aHours = (a['callStats']?['totalCallHours'] as num?)?.toDouble() ?? 0;
      final bHours = (b['callStats']?['totalCallHours'] as num?)?.toDouble() ?? 0;
      return bHours.compareTo(aHours);
    });
    
    final topPerformers = ccVolunteers.take(5).toList();
    
    if (topPerformers.isEmpty) {
      return SizedBox.shrink();
    }
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber.shade700),
              SizedBox(width: 8),
              Text(
                "Top Performers",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          // List view instead of chart for better compatibility
          Column(
            children: topPerformers.asMap().entries.map((entry) {
              final index = entry.key;
              final volunteer = entry.value;
              final hours = (volunteer['callStats']?['totalCallHours'] as num?)?.toDouble() ?? 0;
              final calls = (volunteer['callStats']?['totalCalls'] as int?) ?? 0;
              final name = volunteer['fullName'] as String? ?? 'Unknown';
              final maxHours = topPerformers.isNotEmpty 
                  ? (topPerformers.first['callStats']?['totalCallHours'] as num?)?.toDouble() ?? 1
                  : 1;
              final percentage = (maxHours > 0 ? (hours / maxHours) : 0.0) as double;
              
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: index == 0 
                      ? Colors.amber.shade50 
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: index == 0 
                        ? Colors.amber.shade200 
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: index == 0 
                            ? Colors.amber.shade700 
                            : AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.accentGreen,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '${hours.toStringAsFixed(1)}h',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accentGreen,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text(
                            '$calls calls',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQueriesSection() {
    final recentQueries = _queries.take(5).toList();
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.question_answer, color: AppColors.primaryBlue),
                  SizedBox(width: 8),
                  Text(
                    "Recent Queries",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (_pendingQueries > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$_pendingQueries pending",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          if (recentQueries.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "No queries yet",
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
            )
          else
            ...recentQueries.map((query) {
              final isPending = query['status'] == 'pending';
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPending ? Colors.red.withOpacity(0.05) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPending ? Colors.red.withOpacity(0.3) : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            query['volunteer']?['fullName'] ?? 'Unknown',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPending ? Colors.red : Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPending ? 'Pending' : 'Replied',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      query['query'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
