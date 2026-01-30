import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'admin_mentee_management.dart';
import 'admin_query_management.dart';
import 'config/api_config.dart';
import 'config/app_colors.dart';
import 'screens/admin/ccp_admin_dashboard_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final String baseUrl = ApiConfig.apiUrl;

  late TabController _tabController;
  List<dynamic> pendingVolunteers = [];
  List<dynamic> allVolunteers = [];
  bool isLoading = false;
  String? adminToken;

  // Theme colors (using AppColors)
  static final primaryColor = AppColors.primaryBlue;
  static final secondaryColor = AppColors.secondaryBlue;
  static final backgroundColor = AppColors.backgroundLight1;
  static const cardColor = Colors.white;
  static final textPrimary = AppColors.textDark;
  static final textSecondary = AppColors.gray1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    adminToken = await secureStorage.read(key: "adminToken");
    if (adminToken != null) {
      await _fetchPendingVolunteers();
      await _fetchAllVolunteers();
    }
  }

  Future<void> _fetchPendingVolunteers() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/pending-volunteers'),
        headers: {
          'Authorization': 'Bearer $adminToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => pendingVolunteers = data['volunteers'] ?? []);
      } else {
        _showError('Failed to fetch pending volunteers');
      }
    } catch (e) {
      _showError('Network error: $e');
    }
    setState(() => isLoading = false);
  }

  Future<void> _fetchAllVolunteers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/volunteers'),
        headers: {
          'Authorization': 'Bearer $adminToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => allVolunteers = data['volunteers'] ?? []);
      } else {
        _showError('Failed to fetch volunteers');
      }
    } catch (e) {
      _showError('Network error: $e');
    }
  }

  Future<void> _approveVolunteer(String volunteerId) async {
    // Show loading indicator
    _showLoadingOverlay();

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/approve/$volunteerId'),
        headers: {
          'Authorization': 'Bearer $adminToken',
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);
      Navigator.pop(context); // Hide loading

      if (response.statusCode == 200) {
        _showSuccess('Volunteer approved successfully! 🎉');
        await _fetchPendingVolunteers();
        await _fetchAllVolunteers();
      } else {
        _showError(data['message'] ?? 'Failed to approve volunteer');
      }
    } catch (e) {
      Navigator.pop(context); // Hide loading
      _showError('Network error: $e');
    }
  }

  Future<void> _rejectVolunteer(String volunteerId) async {
    // Show loading indicator
    _showLoadingOverlay();

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/reject/$volunteerId'),
        headers: {
          'Authorization': 'Bearer $adminToken',
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);
      Navigator.pop(context); // Hide loading

      if (response.statusCode == 200) {
        _showSuccess('Volunteer application rejected');
        await _fetchPendingVolunteers();
        await _fetchAllVolunteers();
      } else {
        _showError(data['message'] ?? 'Failed to reject volunteer');
      }
    } catch (e) {
      Navigator.pop(context); // Hide loading
      _showError('Network error: $e');
    }
  }

  void _showDeleteVolunteerDialog(Map<String, dynamic> volunteer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Delete Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Delete Volunteer',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Volunteer Name
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_rounded,
                        color: textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        volunteer['fullName'] ?? 'Unknown',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Warning Message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'This action cannot be undone',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'The following data will be permanently deleted:',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDeleteItem('All call notes and records'),
                      _buildDeleteItem('Session history'),
                      _buildDeleteItem('Query records'),
                      _buildDeleteItem('Rating information'),
                      _buildDeleteItem('Activity tracking data'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Note about mentees
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.blue.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Note: Volunteers with assigned mentees cannot be deleted',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.shade400,
                              Colors.red.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.shade400.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteVolunteer(volunteer['_id']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Delete',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVolunteer(String volunteerId) async {
    // Show modern loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.red.shade400,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.delete_rounded,
                      color: Colors.red.shade400,
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Deleting Volunteer...',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/volunteers/$volunteerId'),
        headers: {
          'Authorization': 'Bearer $adminToken',
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);
      Navigator.pop(context); // Hide loading dialog

      if (response.statusCode == 200) {
        _showSuccess('Volunteer deleted successfully');
        await _fetchPendingVolunteers();
        await _fetchAllVolunteers();
      } else {
        // Check if error is about assigned mentees
        String errorMessage = data['message'] ?? 'Failed to delete volunteer';
        if (errorMessage.toLowerCase().contains('mentee') ||
            errorMessage.toLowerCase().contains('assigned')) {
          _showError(
            'Cannot delete: This volunteer has assigned mentees. Please unassign all mentees first.',
          );
        } else {
          _showError(errorMessage);
        }
      }
    } catch (e) {
      Navigator.pop(context); // Hide loading dialog
      _showError('Network error: $e');
    }
  }

  void _showLoadingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'Processing...',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _logout() async {
    await secureStorage.delete(key: "adminToken");
    Navigator.pushReplacementNamed(context, "/admin-login");
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingVolunteersView() {
    return RefreshIndicator(
      onRefresh: _fetchPendingVolunteers,
      color: primaryColor,
      child:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : pendingVolunteers.isEmpty
              ? _buildEmptyState(
                'No pending volunteers',
                'All volunteer applications have been reviewed!',
                Icons.task_alt_rounded,
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pendingVolunteers.length,
                itemBuilder: (context, index) {
                  return _buildModernVolunteerCard(
                    pendingVolunteers[index],
                    showActions: true,
                  );
                },
              ),
    );
  }

  Widget _buildAllVolunteersView() {
    return RefreshIndicator(
      onRefresh: _fetchAllVolunteers,
      color: primaryColor,
      child:
          allVolunteers.isEmpty
              ? _buildEmptyState(
                'No volunteers found',
                'Start by approving some volunteer applications!',
                Icons.people_outline_rounded,
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: allVolunteers.length,
                itemBuilder: (context, index) {
                  return _buildModernVolunteerCard(allVolunteers[index]);
                },
              ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
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
            child: Icon(icon, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(fontSize: 14, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildModernVolunteerCard(
    Map<String, dynamic> volunteer, {
    bool showActions = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showVolunteerDetails(volunteer, showActions),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    // Profile Picture with status indicator
                    Hero(
                      tag: 'volunteer_${volunteer['_id']}',
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _getStatusColor(
                                  volunteer['approvalStatus'],
                                ),
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: primaryColor.withOpacity(0.1),
                              child:
                                  volunteer['photoUrl'] != null &&
                                          volunteer['photoUrl']
                                              .toString()
                                              .isNotEmpty
                                      ? ClipOval(
                                        child: Image.network(
                                          volunteer['photoUrl'],
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                                    Icons.person_rounded,
                                                    size: 32,
                                                    color: primaryColor,
                                                  ),
                                        ),
                                      )
                                      : Icon(
                                        Icons.person_rounded,
                                        size: 32,
                                        color: primaryColor,
                                      ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  volunteer['approvalStatus'],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: cardColor, width: 2),
                              ),
                              child: Icon(
                                _getStatusIcon(volunteer['approvalStatus']),
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Volunteer Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            volunteer['fullName'] ?? 'N/A',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            volunteer['email'] ?? 'N/A',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                          if (volunteer['phone'] != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              volunteer['phone'],
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (volunteer['currentLocation'] != null) ...[
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    volunteer['currentLocation'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    volunteer['approvalStatus'],
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  volunteer['approvalStatus']?.toUpperCase() ??
                                      'PENDING',
                                  style: GoogleFonts.poppins(
                                    color: _getStatusColor(
                                      volunteer['approvalStatus'],
                                    ),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Add skills preview tags
                          if (volunteer['skills'] != null &&
                              volunteer['skills'].isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildCompactSkillsPreview(volunteer['skills']),
                          ],
                          // Add preferred roles preview if no skills or to complement skills
                          if ((volunteer['skills'] == null ||
                                  volunteer['skills'].isEmpty) &&
                              volunteer['preferredRoles'] != null &&
                              volunteer['preferredRoles'].isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildCompactRolesPreview(
                              volunteer['preferredRoles'],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Delete Button (only for non-pending volunteers)
                    if (!showActions &&
                        volunteer['approvalStatus'] != 'pending') ...[
                      IconButton(
                        onPressed: () => _showDeleteVolunteerDialog(volunteer),
                        icon: Icon(
                          Icons.delete_rounded,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    
                    // Arrow Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),

                if (showActions) ...[
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'Approve',
                          Icons.check_circle_rounded,
                          Colors.green,
                          () => _approveVolunteer(volunteer['_id']),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          'Reject',
                          Icons.cancel_rounded,
                          Colors.red,
                          () => _rejectVolunteer(volunteer['_id']),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }

  Widget _buildCompactSkillsPreview(List<dynamic> skills) {
    if (skills.isEmpty) return const SizedBox.shrink();

    // Parse the skills properly using our helper function
    List<String> parsedSkills = _parseItemsArray(skills);
    if (parsedSkills.isEmpty) return const SizedBox.shrink();

    // Define more vibrant colors for compact skill bubbles
    final List<Color> compactColors = [
      AppColors.purpleGradientEnd, // Purple
      AppColors.accentGreen, // Forest Green
      AppColors.accentOrange, // Coral Orange
      AppColors.tertiaryBlue, // Cyan
      AppColors.accentYellow, // Bright Yellow
      AppColors.accentOrange, // Orange
      AppColors.secondaryBlue, // Teal Blue
      AppColors.primaryBlue, // Primary Blue
      AppColors.accentGreen, // Accent Green
      AppColors.accentOrange, // Accent Orange
    ];

    // Show only first 3 skills in compact view
    final displaySkills = parsedSkills.take(3).toList();
    final hasMore = parsedSkills.length > 3;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        ...displaySkills.asMap().entries.map((entry) {
          final index = entry.key;
          final skill = entry.value;
          final color = compactColors[index % compactColors.length];

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    skill,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 0.5),
                          blurRadius: 1,
                          color: Colors.black.withOpacity(0.4),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        if (hasMore)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[600]!, Colors.grey[500]!],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              '+${parsedSkills.length - 3}',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompactRolesPreview(List<dynamic> roles) {
    if (roles.isEmpty) return const SizedBox.shrink();

    // Define professional colors for preferred roles
    final List<Color> roleColors = [
      const Color(0xFF5F27CD), // Deep Purple
      const Color(0xFF00D2D3), // Turquoise
      const Color(0xFFFF6348), // Orange Red
      const Color(0xFF1DD1A1), // Green
      const Color(0xFF3742FA), // Blue
      const Color(0xFFFF3838), // Red
      const Color(0xFF2ED573), // Light Green
      const Color(0xFFFF6B35), // Coral
      const Color(0xFF5352ED), // Purple Blue
      const Color(0xFF70A1FF), // Light Blue
    ];

    // Show only first 3 roles in compact view
    final displayRoles = roles.take(3).toList();
    final hasMore = roles.length > 3;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        ...displayRoles.asMap().entries.map((entry) {
          final index = entry.key;
          final role = entry.value.toString();
          final color = roleColors[index % roleColors.length];

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(
                6,
              ), // More rectangular for roles
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    role,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 0.5),
                          blurRadius: 1,
                          color: Colors.black.withOpacity(0.4),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        if (hasMore)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[600]!, Colors.grey[500]!],
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              '+${roles.length - 3}',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Icons.check_rounded;
      case 'rejected':
        return Icons.close_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  void _showVolunteerDetails(Map<String, dynamic> volunteer, bool showActions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            expand: false,
            builder:
                (context, scrollController) => Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Drag Handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            children: [
                              // Header
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _getStatusColor(
                                          volunteer['approvalStatus'],
                                        ),
                                        width: 3,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 40,
                                      backgroundImage:
                                          volunteer['photoUrl'] != null
                                              ? NetworkImage(
                                                volunteer['photoUrl'],
                                              )
                                              : null,
                                      backgroundColor: primaryColor.withOpacity(
                                        0.1,
                                      ),
                                      child:
                                          volunteer['photoUrl'] == null
                                              ? Icon(
                                                Icons.person_rounded,
                                                size: 40,
                                                color: primaryColor,
                                              )
                                              : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          volunteer['fullName'] ?? 'N/A',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24,
                                            color: textPrimary,
                                          ),
                                        ),
                                        Text(
                                          volunteer['email'] ?? 'N/A',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: textSecondary,
                                          ),
                                        ),
                                        if (volunteer['phone'] != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.phone,
                                                size: 16,
                                                color: textSecondary,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                volunteer['phone'],
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  color: textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              volunteer['approvalStatus'],
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            volunteer['approvalStatus']
                                                    ?.toUpperCase() ??
                                                'PENDING',
                                            style: GoogleFonts.poppins(
                                              color: _getStatusColor(
                                                volunteer['approvalStatus'],
                                              ),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // Details
                              ..._buildDetailsSections(volunteer),

                              if (showActions) ...[
                                const SizedBox(height: 32),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildActionButton(
                                        'Approve Volunteer',
                                        Icons.check_circle_rounded,
                                        Colors.green,
                                        () {
                                          Navigator.pop(context);
                                          _approveVolunteer(volunteer['_id']);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildActionButton(
                                        'Reject Application',
                                        Icons.cancel_rounded,
                                        Colors.red,
                                        () {
                                          Navigator.pop(context);
                                          _rejectVolunteer(volunteer['_id']);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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

  List<Widget> _buildDetailsSections(Map<String, dynamic> volunteer) {
    return [
      _buildDetailsSection('Personal Information', [
        _buildModernInfoRow(
          Icons.cake_rounded,
          'Date of Birth',
          volunteer['dob']?.substring(0, 10),
        ),
        _buildModernInfoRow(
          Icons.person_outline_rounded,
          'Gender',
          volunteer['gender'],
        ),
        _buildModernInfoRow(
          Icons.bloodtype_rounded,
          'Blood Group',
          volunteer['bloodGroup'],
        ),
        _buildModernInfoRow(
          Icons.location_on_rounded,
          'Address',
          volunteer['address'],
        ),
        _buildModernInfoRow(
          Icons.location_city_rounded,
          'Current Location',
          volunteer['currentLocation'],
        ),
        _buildModernInfoRow(Icons.phone_rounded, 'Phone', volunteer['phone']),
        _buildModernInfoRow(
          Icons.verified_user_rounded,
          'Email Verified',
          volunteer['verified'] == true ? 'Yes' : 'No',
        ),
      ]),

      const SizedBox(height: 24),

      _buildDetailsSection('Professional & Educational Details', [
        _buildModernInfoRow(
          Icons.work_rounded,
          'Current Occupation',
          volunteer['currentOccupation'],
        ),
        _buildModernInfoRow(
          Icons.school_rounded,
          'Highest Qualification',
          volunteer['highestQualification'],
        ),
        _buildModernInfoRow(
          Icons.business_rounded,
          'Organization',
          volunteer['organizationName']?.isNotEmpty == true
              ? volunteer['organizationName']
              : 'Not specified',
        ),
        _buildModernInfoRow(
          Icons.corporate_fare_rounded,
          'Corporate Experience',
          volunteer['corporateExperience'] == true ? 'Yes' : 'No',
        ),
        if (volunteer['skills'] != null && volunteer['skills'].isNotEmpty)
          _buildSkillsChips('Skills', volunteer['skills']),
        if (volunteer['preferredRoles'] != null &&
            volunteer['preferredRoles'].isNotEmpty)
          _buildSkillsChips('Preferred Roles', volunteer['preferredRoles']),
        if (volunteer['skillsDesc'] != null &&
            volunteer['skillsDesc'].isNotEmpty)
          _buildTextSection('Skills Description', volunteer['skillsDesc']),
      ]),

      const SizedBox(height: 24),

      _buildDetailsSection('Volunteering Details', [
        _buildModernInfoRow(
          Icons.schedule_rounded,
          'Hours Per Week',
          volunteer['hoursPerWeek'],
        ),
        _buildModernInfoRow(
          Icons.apps_rounded,
          'Interested Program',
          volunteer['interestedProgram'],
        ),
        _buildModernInfoRow(
          Icons.language_rounded,
          'Meiteilon',
          volunteer['meiteilon'],
        ),
        _buildModernInfoRow(
          Icons.volunteer_activism_rounded,
          'Prior Volunteering',
          volunteer['priorVolunteering'] == true ? 'Yes' : 'No',
        ),
        if (volunteer['priorVolunteeringDesc'] != null &&
            volunteer['priorVolunteeringDesc'].isNotEmpty)
          _buildTextSection(
            'Prior Volunteering Description',
            volunteer['priorVolunteeringDesc'],
          ),
        if (volunteer['specialRequirements'] != null &&
            volunteer['specialRequirements'].isNotEmpty)
          _buildTextSection(
            'Special Requirements',
            volunteer['specialRequirements'],
          ),
        if (volunteer['conflictSituation'] != null &&
            volunteer['conflictSituation'].isNotEmpty)
          _buildTextSection(
            'Conflict Situation Handling',
            volunteer['conflictSituation'],
          ),
      ]),

      const SizedBox(height: 24),

      _buildDetailsSection('Application Status & Admin Info', [
        _buildModernInfoRow(
          Icons.approval_rounded,
          'Approval Status',
          volunteer['approvalStatus'],
        ),
        _buildModernInfoRow(
          Icons.admin_panel_settings_rounded,
          'Approved By',
          volunteer['approvedBy'],
        ),
        _buildModernInfoRow(Icons.person_rounded, 'Role', volunteer['role']),
        _buildModernInfoRow(
          Icons.schedule_rounded,
          'Application Date',
          volunteer['createdAt']?.substring(0, 10),
        ),
        _buildModernInfoRow(
          Icons.update_rounded,
          'Last Updated',
          volunteer['updatedAt']?.substring(0, 10),
        ),
      ]),

      const SizedBox(height: 24),

      _buildDetailsSection('Policy & Compliance', [
        _buildModernInfoRow(
          Icons.policy_rounded,
          'POSH Policy Accepted',
          volunteer['poshPolicyAccepted'] == true ? 'Yes' : 'No',
        ),
        _buildModernInfoRow(
          Icons.child_care_rounded,
          'Child Protection Undertaking',
          volunteer['childProtectionUndertaking'] == true ? 'Yes' : 'No',
        ),
        _buildModernInfoRow(
          Icons.school_rounded,
          'Willing for Orientation',
          volunteer['willingOrientation'] == true ? 'Yes' : 'No',
        ),
      ]),

      if (volunteer['socialMedia'] != null &&
          volunteer['socialMedia'].isNotEmpty) ...[
        const SizedBox(height: 24),
        _buildDetailsSection('Contact & Social', [
          _buildModernInfoRow(
            Icons.share_rounded,
            'Social Media',
            volunteer['socialMedia'],
          ),
        ]),
      ],

      const SizedBox(height: 24),

      _buildDetailsSection('Reference Information', [
        _buildModernInfoRow(
          Icons.person_rounded,
          'Reference Name',
          volunteer['referenceName'],
        ),
        _buildModernInfoRow(
          Icons.phone_rounded,
          'Reference Phone',
          volunteer['referencePhone'],
        ),
        _buildModernInfoRow(
          Icons.family_restroom_rounded,
          'Reference Relation',
          volunteer['referenceRelation'],
        ),
        _buildModernInfoRow(
          Icons.business_rounded,
          'Reference Affiliation',
          volunteer['referenceAffiliation'],
        ),
      ]),

      if (volunteer['whyVolunteer'] != null &&
          volunteer['whyVolunteer'].isNotEmpty) ...[
        const SizedBox(height: 24),
        _buildDetailsSection('Motivation', [
          _buildTextSection('Why Volunteer?', volunteer['whyVolunteer']),
        ]),
      ],

      if (volunteer['trustworthyMeaning'] != null &&
          volunteer['trustworthyMeaning'].isNotEmpty) ...[
        const SizedBox(height: 24),
        _buildDetailsSection('Personal Values', [
          _buildTextSection(
            'What does being trustworthy mean?',
            volunteer['trustworthyMeaning'],
          ),
        ]),
      ],

      const SizedBox(height: 24),

      _buildDetailsSection('Documents & Photos', [
        if (volunteer['photoUrl'] != null)
          _buildImageSection('Profile Photo', volunteer['photoUrl']),
        if (volunteer['aadhar'] != null)
          _buildDocumentSection('Aadhar Document', volunteer['aadhar']),
        if (volunteer['referencePhotoUrl'] != null)
          _buildImageSection('Reference Photo', volunteer['referencePhotoUrl']),
        if (volunteer['referenceAadhar'] != null)
          _buildDocumentSection(
            'Reference Aadhar',
            volunteer['referenceAadhar'],
          ),
      ]),
    ];
  }

  Widget _buildDetailsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String? value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value ?? 'N/A',
                  style: GoogleFonts.poppins(fontSize: 14, color: textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to parse skill/role arrays properly
  List<String> _parseItemsArray(List<dynamic> items) {
    List<String> parsedItems = [];
    for (var item in items) {
      if (item is String) {
        // If it's a string that looks like an array or contains commas, split it
        String cleanItem = item.trim();

        // Remove array brackets if present
        cleanItem = cleanItem.replaceAll(RegExp(r'^\[|\]$'), '');

        // If it contains commas, split it
        if (cleanItem.contains(',')) {
          List<String> splitItems =
              cleanItem
                  .split(',')
                  .map((s) => s.trim())
                  .map(
                    (s) => s.replaceAll('"', '').replaceAll("'", ''),
                  ) // Remove quotes
                  .where((s) => s.isNotEmpty)
                  .toList();
          parsedItems.addAll(splitItems);
        } else {
          // Single item, just clean it up
          cleanItem = cleanItem
              .replaceAll('"', '')
              .replaceAll("'", ''); // Remove quotes
          if (cleanItem.isNotEmpty) {
            parsedItems.add(cleanItem);
          }
        }
      } else {
        // Not a string, convert to string and add
        String itemStr = item.toString().trim();
        if (itemStr.isNotEmpty) {
          parsedItems.add(itemStr);
        }
      }
    }

    // Remove duplicates and empty items
    return parsedItems.where((item) => item.isNotEmpty).toSet().toList();
  }

  Widget _buildSkillsChips(String label, List<dynamic> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    // Parse the items properly
    List<String> parsedItems = _parseItemsArray(items);

    if (parsedItems.isEmpty) return const SizedBox.shrink();

    // Define different vibrant colors for each individual bubble
    final List<Color> bubbleColors = [
      // Vibrant colors for individual bubbles
      const Color(0xFF6C5CE7), // Purple
      const Color(0xFF00B894), // Teal
      const Color(0xFFFF6B6B), // Red
      const Color(0xFF4ECDC4), // Cyan
      const Color(0xFFFFD93D), // Yellow
      const Color(0xFF6C5CE7), // Purple
      const Color(0xFFFF7675), // Light Red
      const Color(0xFF74B9FF), // Blue
      const Color(0xFFA29BFE), // Light Purple
      const Color(0xFF55A3FF), // Sky Blue
      const Color(0xFFFF9F43), // Orange
      const Color(0xFF00D2D3), // Turquoise
      const Color(0xFFFF6348), // Orange Red
      const Color(0xFF1DD1A1), // Green
      const Color(0xFFFECA57), // Golden
      const Color(0xFF5F27CD), // Deep Purple
      const Color(0xFF00D8FF), // Bright Blue
      const Color(0xFFFF3838), // Bright Red
      const Color(0xFF7BED9F), // Light Green
      const Color(0xFFFF6B35), // Coral
    ];

    final bool isSkills = label.toLowerCase().contains('skill');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        isSkills
                            ? [Colors.blue[400]!, Colors.purple[400]!]
                            : [Colors.deepPurple[400]!, Colors.indigo[400]!],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSkills ? Icons.star_rounded : Icons.work_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSkills ? Colors.blue[50] : Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${parsedItems.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSkills ? Colors.blue[600] : Colors.purple[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                parsedItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final color = bubbleColors[index % bubbleColors.length];

                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, color.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            item,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),

          // Add a summary at the bottom
          if (parsedItems.length > 5) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSkills ? Colors.blue[50] : Colors.purple[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSkills ? Colors.blue[100]! : Colors.purple[100]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: isSkills ? Colors.blue[600] : Colors.purple[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Total ${parsedItems.length} ${isSkills ? 'skills' : 'preferred roles'} available',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSkills ? Colors.blue[700] : Colors.purple[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextSection(String label, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.5,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(String label, String imageUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.image_rounded, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              height: 120,
              width: 120,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[400],
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSection(String label, String documentUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.description_rounded,
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Document Available',
                  style: GoogleFonts.poppins(fontSize: 14, color: textPrimary),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement document viewing
              _showSuccess('Document viewing will be implemented');
            },
            icon: Icon(Icons.open_in_new_rounded, size: 16),
            label: Text('View', style: GoogleFonts.poppins(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with gradient
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Volunteers Management',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, secondaryColor],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () async {
                  await _fetchPendingVolunteers();
                  await _fetchAllVolunteers();
                },
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Statistics Cards
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Pending Reviews',
                      pendingVolunteers.length.toString(),
                      Icons.pending_actions_rounded,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total Volunteers',
                      allVolunteers.length.toString(),
                      Icons.people_rounded,
                      primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: primaryColor,
                unselectedLabelColor: textSecondary,
                indicatorColor: primaryColor,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Pending Approval'),
                  Tab(text: 'All Volunteers'),
                ],
              ),
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingVolunteersView(),
                _buildAllVolunteersView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: const Color(0xFFF8FFFE), child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
