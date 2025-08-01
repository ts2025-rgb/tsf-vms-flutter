import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final String baseUrl = "http://localhost:8000/api";
  
  late TabController _tabController;
  List<dynamic> pendingVolunteers = [];
  List<dynamic> allVolunteers = [];
  bool isLoading = false;
  String? adminToken;

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
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/approve/$volunteerId'),
        headers: {
          'Authorization': 'Bearer $adminToken',
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        _showSuccess('Volunteer approved successfully');
        await _fetchPendingVolunteers();
        await _fetchAllVolunteers();
      } else {
        _showError(data['message'] ?? 'Failed to approve volunteer');
      }
    } catch (e) {
      _showError('Network error: $e');
    }
  }

  Future<void> _rejectVolunteer(String volunteerId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/reject/$volunteerId'),
        headers: {
          'Authorization': 'Bearer $adminToken',
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        _showSuccess('Volunteer rejected successfully');
        await _fetchPendingVolunteers();
        await _fetchAllVolunteers();
      } else {
        _showError(data['message'] ?? 'Failed to reject volunteer');
      }
    } catch (e) {
      _showError('Network error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _logout() async {
    await secureStorage.delete(key: "adminToken");
    Navigator.pushReplacementNamed(context, "/admin-login");
  }

 Widget _buildVolunteerCard(Map<String, dynamic> volunteer, {bool showActions = false}) {
  return InkWell(
    onTap: () {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: volunteer['photoUrl'] != null
                    ? NetworkImage(volunteer['photoUrl'])
                    : null,
                backgroundColor: Colors.grey[300],
                child: volunteer['photoUrl'] == null
                    ? const Icon(Icons.person, size: 24)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  volunteer['fullName'] ?? 'N/A',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Email', volunteer['email']),
                _buildInfoRow('Verified', volunteer['verified']?.toString()),
                _buildInfoRow('Role', volunteer['role']),
                _buildInfoRow('Approval Status', volunteer['approvalStatus']),
                _buildInfoRow('Approved By', volunteer['approvedBy']),
                _buildInfoRow('Created At', volunteer['createdAt']?.substring(0, 10)),
                _buildInfoRow('Updated At', volunteer['updatedAt']?.substring(0, 10)),
                _buildInfoRow('Address', volunteer['address']),
                _buildInfoRow('DOB', volunteer['dob']?.substring(0, 10)),
                _buildInfoRow('Expertise', volunteer['expertise']),
                _buildInfoRow('Why Volunteer', volunteer['whyVolunteer']),
                if (showActions) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _approveVolunteer(volunteer['_id']);
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: Text('Approve', style: GoogleFonts.poppins()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _rejectVolunteer(volunteer['_id']);
                        },
                        icon: const Icon(Icons.close, size: 18),
                        label: Text('Reject', style: GoogleFonts.poppins()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
    child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: volunteer['photoUrl'] != null
                  ? NetworkImage(volunteer['photoUrl'])
                  : null,
              backgroundColor: Colors.grey[300],
              child: volunteer['photoUrl'] == null
                  ? const Icon(Icons.person, size: 25)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    volunteer['fullName'] ?? 'N/A',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "DOB: ${volunteer['dob']?.substring(0, 10) ?? 'N/A'}",
                    style: GoogleFonts.poppins(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    "Expertise: ${volunteer['expertise'] ?? 'N/A'}",
                    style: GoogleFonts.poppins(
                      color: Colors.teal[700],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(volunteer['approvalStatus']),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                volunteer['approvalStatus']?.toUpperCase() ?? 'PENDING',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: GoogleFonts.poppins(fontSize: 12),
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
      backgroundColor: const Color(0xFFEFFAF6),
      appBar: AppBar(
        backgroundColor: Colors.teal[700],
        title: Text('Admin Dashboard', style: GoogleFonts.poppins()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchPendingVolunteers();
              _fetchAllVolunteers();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Text(
                'Pending (${pendingVolunteers.length})',
                style: GoogleFonts.poppins(),
              ),
            ),
            Tab(
              child: Text(
                'All Volunteers (${allVolunteers.length})',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pending Volunteers Tab
          RefreshIndicator(
            onRefresh: _fetchPendingVolunteers,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : pendingVolunteers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No pending volunteers',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: pendingVolunteers.length,
                        itemBuilder: (context, index) {
                          return _buildVolunteerCard(
                            pendingVolunteers[index],
                            showActions: true,
                          );
                        },
                      ),
          ),
          // All Volunteers Tab
          RefreshIndicator(
            onRefresh: _fetchAllVolunteers,
            child: allVolunteers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No volunteers found',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: allVolunteers.length,
                    itemBuilder: (context, index) {
                      return _buildVolunteerCard(allVolunteers[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}