import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'create_mentee_page.dart';
import 'config/api_config.dart';
import 'config/app_colors.dart';

class AdminMenteeManagementPage extends StatefulWidget {
  const AdminMenteeManagementPage({super.key});

  @override
  State<AdminMenteeManagementPage> createState() => _AdminMenteeManagementPageState();
}

class _AdminMenteeManagementPageState extends State<AdminMenteeManagementPage> {
  final String baseUrl = ApiConfig.apiUrl;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  
  List<dynamic> _mentees = [];
  List<dynamic> _volunteers = [];
  List<dynamic> _programs = [];
  List<dynamic> _allCCVolunteers = [];
  List<dynamic> _approvedCCVolunteers = [];
  String? _companionConnectProgramId;
  String? _companionConnectProgramMongoId;
  bool _loading = true;
  String _filter = 'all'; // all, assigned, unassigned

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    await _fetchPrograms(); // Fetch programs first to get ID
    await Future.wait([
      _fetchMentees(),
      _fetchVolunteers(),
    ]);
    setState(() => _loading = false);
  }

  Future<void> _fetchPrograms() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/programs'),
      );

      print('Programs Response Status: ${response.statusCode}');
      print('Programs Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _programs = data['programs'] ?? [];
            print('Total programs fetched: ${_programs.length}');
            
            // Print all program names to debug
            for (var p in _programs) {
              print('Program: ${p['name']} (ID: ${p['id']})'); // Changed from _id to id
            }
            
            // Find Companion Connect program ID (case-insensitive)
            final ccProgram = _programs.firstWhere(
              (p) => p['name']?.toString().toLowerCase() == 'companion connect',
              orElse: () => null,
            );
            
            if (ccProgram != null) {
              _companionConnectProgramId = ccProgram['id']; // API id field
              _companionConnectProgramMongoId = ccProgram['_id']; // MongoDB _id field
              print('✅ Found Companion Connect ID: $_companionConnectProgramId, MongoID: $_companionConnectProgramMongoId');
            } else {
              print('❌ Companion Connect program not found!');
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching programs: $e');
    }
  }

  Future<void> _fetchMentees() async {
    try {
      final token = await secureStorage.read(key: "adminToken"); // Changed from "token" to "adminToken"
      
      final response = await http.get(
        Uri.parse('$baseUrl/companion-connect/admin/mentees'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Mentees Response Status: ${response.statusCode}');
      print('Mentees Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      if (response.statusCode == 200) {
        // Check if response is actually JSON
        if (response.body.trim().startsWith('{') || response.body.trim().startsWith('[')) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            setState(() {
              _mentees = data['mentees'] ?? [];
            });
          }
        } else {
          print('ERROR: Response is not JSON, got HTML');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('API Error: Server returned HTML instead of JSON'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else if (response.statusCode == 404) {
        print('ERROR: Endpoint not found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Endpoint not found. Backend may not be ready.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error fetching mentees: $e');
    }
  }

  Future<void> _fetchVolunteers() async {
    try {
      final token = await secureStorage.read(key: "adminToken");
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/volunteers'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('📡 Volunteers API Response Status: ${response.statusCode}');
        print('📡 Volunteers API Response: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
        
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final allVolunteers = (data['volunteers'] as List);
          print('📊 Total volunteers from API: ${allVolunteers.length}');
          
          // Debug: Check first few volunteers
          if (allVolunteers.isNotEmpty) {
            print('🔍 Sample volunteer data: ${allVolunteers[0]}');
          }
          
          // Debug: Count volunteers by role
          final volunteersByRole = allVolunteers.where((v) => v['role'] == 'volunteer').length;
          final allUsers = allVolunteers.length;
          print('👥 Total users: $allUsers, Volunteers: $volunteersByRole');
          
          // All volunteers enrolled in Companion Connect program
          _allCCVolunteers = (_companionConnectProgramId != null || _companionConnectProgramMongoId != null) ? allVolunteers.where((v) {
            if (v['role'] != 'volunteer') {
              return false;
            }
            if (v['interestedPrograms'] == null) {
              print('⚠️ Volunteer ${v['fullName']} has no interestedPrograms');
              return false;
            }
            final interestedPrograms = v['interestedPrograms'] as List;
            print('📋 Volunteer ${v['fullName']} interestedPrograms: $interestedPrograms');
            print('🔍 Looking for CC ID: $_companionConnectProgramId or $_companionConnectProgramMongoId');
            // Check if interestedPrograms contains the Companion Connect program ID
            // Handle both 'id' and '_id' formats in case of API inconsistencies
            final hasCCProgram = interestedPrograms.contains(_companionConnectProgramId) ||
                               interestedPrograms.contains(_companionConnectProgramMongoId);
            if (hasCCProgram) {
              print('✅ Volunteer ${v['fullName']} has CC program');
            } else {
              print('❌ Volunteer ${v['fullName']} does not have CC program');
            }
            return hasCCProgram;
          }).toList() : [];
          
          print('🎯 CC Volunteers found: ${_allCCVolunteers.length}');
          
          // Approved volunteers for assignment
          _approvedCCVolunteers = _allCCVolunteers.where((v) {
            final approvalStatus = v['approvalStatus'] ?? v['status'];
            final isApproved = approvalStatus == 'approved' || 
                             approvalStatus == 'active' || 
                             approvalStatus == true ||
                             approvalStatus == null; // Assume approved if no status field
            if (!isApproved) {
              print('❌ Volunteer ${v['fullName']} not approved (status: $approvalStatus)');
            } else {
              print('✅ Volunteer ${v['fullName']} is approved');
            }
            return isApproved;
          }).toList();
          
          // Fallback: if no approved volunteers found, use all CC volunteers (assume approved by default)
          if (_approvedCCVolunteers.isEmpty && _allCCVolunteers.isNotEmpty) {
            print('⚠️ No approved volunteers found, using all CC volunteers as active');
            _approvedCCVolunteers = _allCCVolunteers;
          }
          
          print('✅ Final Approved CC Volunteers: ${_approvedCCVolunteers.length}');
          
          setState(() {
            // For assignment dialog, use approved volunteers
            _volunteers = _approvedCCVolunteers;
          });
        }
      }
    } catch (e) {
      print('Error fetching volunteers: $e');
    }
  }

  Future<void> _assignMentee(String menteeId, String volunteerId) async {
    try {
      final token = await secureStorage.read(key: "adminToken");
      
      final response = await http.post(
        Uri.parse('$baseUrl/companion-connect/admin/assign-mentee'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'menteeId': menteeId,
          'volunteerId': volunteerId,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mentee assigned successfully!'), backgroundColor: Colors.green),
        );
        _fetchMentees();
        _fetchVolunteers(); // Refresh volunteer list to update indicators
      } else {
        final data = json.decode(response.body);
        final errorMessage = data['message'] ?? 'Failed to assign mentee';
        
        // Show specific error for already assigned volunteer
        if (errorMessage.contains('already exists') || errorMessage.contains('already has')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Assignment Failed', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('This volunteer already has an active mentee assigned.'),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _unassignMentee(String menteeId) async {
    try {
      final token = await secureStorage.read(key: "adminToken");
      
      final response = await http.post(
        Uri.parse('$baseUrl/companion-connect/admin/unassign-mentee'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'menteeId': menteeId,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mentee unassigned successfully!'), backgroundColor: Colors.green),
        );
        _fetchMentees();
        _fetchVolunteers(); // Refresh volunteer list to update indicators
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  List<dynamic> get _filteredMentees {
    if (_filter == 'assigned') {
      return _mentees.where((m) => m['assignedTo'] != null).toList();
    } else if (_filter == 'unassigned') {
      return _mentees.where((m) => m['assignedTo'] == null).toList();
    }
    return _mentees;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
        title: Text("Mentee Management", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            onPressed: _fetchData,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : Column(
              children: [
                _buildFilterTabs(),
                _buildStats(),
                Expanded(child: _buildMenteeList()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Check if Companion Connect program exists
          if (_companionConnectProgramId == null && _companionConnectProgramMongoId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: Companion Connect program not found in database'),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: _fetchPrograms,
                ),
              ),
            );
            return;
          }

          // Navigate to create mentee page
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateMenteePage(
                companionConnectProgramId: _companionConnectProgramMongoId ?? _companionConnectProgramId!,
              ),
            ),
          );
          
          // Refresh list if mentee was created
          if (result == true) {
            _fetchMentees();
          }
        },
        icon: Icon(Icons.person_add),
        label: Text("Add Mentee"),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBackendNotReadyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 80, color: Colors.orange.shade300),
            const SizedBox(height: 24),
            Text(
              'Backend Not Ready',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The Companion Connect endpoints are not yet implemented.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Required Endpoints:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('GET /api/companion-connect/admin/mentees', style: GoogleFonts.poppins(fontSize: 11)),
                  Text('POST /api/companion-connect/admin/mentees', style: GoogleFonts.poppins(fontSize: 11)),
                  Text('POST /api/companion-connect/admin/assign-mentee', style: GoogleFonts.poppins(fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: Icon(Icons.refresh),
              label: Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildFilterTab('All', 'all', _mentees.length)),
          Expanded(child: _buildFilterTab('Assigned', 'assigned', _mentees.where((m) => m['assignedTo'] != null).length)),
          Expanded(child: _buildFilterTab('Unassigned', 'unassigned', _mentees.where((m) => m['assignedTo'] == null).length)),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String value, int count) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? AppColors.primaryGradient
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final totalCCVolunteers = _allCCVolunteers.length;
    final activeCCVolunteers = _approvedCCVolunteers.length;
    final availableCCVolunteers = _approvedCCVolunteers.where((v) {
      return !_mentees.any((m) => m['assignedTo'] != null && m['assignedTo']['id'] == v['id']);
    }).length;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue.withOpacity(0.1), AppColors.purpleGradientEnd.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.people, 'Total Volunteers', totalCCVolunteers.toString()),
          _buildStatItem(Icons.check_circle, 'Active Volunteers', activeCCVolunteers.toString()),
          _buildStatItem(Icons.person_add, 'Available', availableCCVolunteers.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryBlue),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: const Color.fromARGB(255, 0, 0, 0)),
        ),
      ],
    );
  }

  Widget _buildMenteeList() {
    if (_filteredMentees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No mentees found',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredMentees.length,
      itemBuilder: (context, index) {
        final mentee = _filteredMentees[index];
        return _buildMenteeCard(mentee);
      },
    );
  }

  Widget _buildMenteeCard(Map<String, dynamic> mentee) {
    return _MenteeHoverCard(
      mentee: mentee,
      onAssign: () => _showAssignDialog(mentee),
      onUnassign: () => _showUnassignDialog(mentee),
      onView: () => _showMenteeDetailsDialog(mentee),
      onDelete: () => _showDeleteMenteeDialog(mentee),
    );
  }

  void _showAssignDialog(Map<String, dynamic> mentee) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxWidth: 500),
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
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Assign Volunteer',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 12),
              
              // Mentee Name
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, size: 16, color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    Text(
                      mentee['fullName'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Description
              Text(
                'Select a volunteer to assign:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              
              // Volunteers List
              Container(
                constraints: BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _volunteers.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'No approved volunteers found',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _volunteers.length,
                        itemBuilder: (context, index) {
                          final volunteer = _volunteers[index];
                          final hasAssignedMentee = _mentees.any((m) => 
                            m['assignedTo'] != null && 
                            m['assignedTo']['id'] == volunteer['id']
                          );
                          
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: hasAssignedMentee 
                                ? Colors.grey.shade50
                                : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: hasAssignedMentee 
                                  ? Colors.grey.shade200 
                                  : Colors.transparent,
                              ),
                            ),
                            child: ListTile(
                              enabled: !hasAssignedMentee,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                                    backgroundImage: volunteer['photoUrl'] != null
                                        ? NetworkImage(volunteer['photoUrl'])
                                        : null,
                                    child: volunteer['photoUrl'] == null
                                        ? Icon(Icons.person, color: AppColors.primaryBlue)
                                        : null,
                                  ),
                                  if (hasAssignedMentee)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade600,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: Icon(
                                          Icons.check_circle,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      volunteer['fullName'] ?? 'Unknown',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: hasAssignedMentee ? Colors.grey.shade500 : Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                  if (hasAssignedMentee)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle, size: 10, color: Colors.orange.shade700),
                                          SizedBox(width: 4),
                                          Text(
                                            'ASSIGNED',
                                            style: GoogleFonts.poppins(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    volunteer['email'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: hasAssignedMentee ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  ),
                                  if (hasAssignedMentee)
                                    Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Already has an active mentee',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.orange.shade600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              onTap: hasAssignedMentee ? null : () {
                                Navigator.pop(context);
                                _assignMentee(mentee['id'], volunteer['id']);
                              },
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 24),
              
              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenteeDetailsDialog(Map<String, dynamic> mentee) {
    final TextEditingController fullNameController = TextEditingController(text: mentee['fullName'] ?? '');
    final TextEditingController ageController = TextEditingController(text: mentee['age']?.toString() ?? '');
    final TextEditingController dobController = TextEditingController(
      text: mentee['dob'] != null ? mentee['dob'].toString().substring(0, 10) : '',
    );
    final TextEditingController gradeController = TextEditingController(text: mentee['grade'] ?? '');
    final TextEditingController phoneController = TextEditingController(text: mentee['phone'] ?? '');
    final TextEditingController pointOfContactController = TextEditingController(text: mentee['pointOfContact'] ?? '');
    final TextEditingController notesController = TextEditingController(text: mentee['notes'] ?? '');
    String selectedStatus = mentee['status'] ?? 'active';
    String? selectedGender = mentee['gender'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                child: mentee['photoUrl'] != null && mentee['photoUrl'].toString().isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          mentee['photoUrl'],
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: AppColors.primaryBlue),
                        ),
                      )
                    : Icon(Icons.person, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mentee['fullName'] ?? 'Unknown',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Age: ${mentee['age']} • ${mentee['gender'] ?? 'N/A'}',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Full Name
                  Text('Full Name', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: fullNameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      prefixIcon: Icon(Icons.person, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Age & Gender row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Age', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: ageController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                hintText: '5–25',
                                prefixIcon: Icon(Icons.cake, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Gender', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedGender,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              hint: Text('Select'),
                              items: ['Male', 'Female', 'Other'].map((g) {
                                return DropdownMenuItem(value: g, child: Text(g));
                              }).toList(),
                              onChanged: (value) => setDialogState(() => selectedGender = value),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // DOB
                  Text('Date of Birth (YYYY-MM-DD)', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  const SizedBox(height: 4),
                  Text(
                    'Note: changing DOB will not auto-recalculate age',
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.orange.shade700),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: dobController,
                    keyboardType: TextInputType.datetime,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      hintText: 'YYYY-MM-DD',
                      prefixIcon: Icon(Icons.calendar_today, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status
                  Text('Status', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: ['active', 'paused', 'completed'].map((s) {
                      return DropdownMenuItem(value: s, child: Text(s.toUpperCase()));
                    }).toList(),
                    onChanged: (value) => setDialogState(() => selectedStatus = value!),
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  Text('Phone', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      prefixIcon: Icon(Icons.phone, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grade
                  Text('Grade', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: gradeController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      prefixIcon: Icon(Icons.school, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Point of Contact
                  Text('Point of Contact', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: pointOfContactController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  Text('Notes', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      hintText: 'Additional notes...',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Read-only info
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRowDialog(Icons.school, 'Program', mentee['program']?['name'] ?? 'N/A'),
                        if (mentee['assignedTo'] != null)
                          _buildInfoRowDialog(Icons.person, 'Assigned To', mentee['assignedTo']['fullName'] ?? 'N/A'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final fields = <String, dynamic>{
                  'status': selectedStatus,
                };
                if (fullNameController.text.trim().isNotEmpty) fields['fullName'] = fullNameController.text.trim();
                final ageVal = int.tryParse(ageController.text.trim());
                if (ageVal != null) fields['age'] = ageVal;
                if (dobController.text.trim().isNotEmpty) fields['dob'] = dobController.text.trim();
                if (selectedGender != null) fields['gender'] = selectedGender;
                if (gradeController.text.trim().isNotEmpty) fields['grade'] = gradeController.text.trim();
                if (phoneController.text.trim().isNotEmpty) fields['phone'] = phoneController.text.trim();
                if (pointOfContactController.text.trim().isNotEmpty) fields['pointOfContact'] = pointOfContactController.text.trim();
                if (notesController.text.trim().isNotEmpty) fields['notes'] = notesController.text.trim();

                await _updateMenteeDetails(mentee['id'], fields);
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRowDialog(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text('$label: ', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _updateMenteeDetails(
    String menteeId,
    Map<String, dynamic> fields,
  ) async {
    try {
      final token = await secureStorage.read(key: "adminToken");

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication token not found. Please login again.'), backgroundColor: Colors.red),
        );
        return;
      }

      print('🔑 Updating mentee $menteeId');
      print('📝 Update payload: $fields');

      final response = await http.patch(
        Uri.parse('$baseUrl/companion-connect/admin/mentees/$menteeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(fields),
      );

      print('📥 Update Response Status: ${response.statusCode}');
      print('📥 Update Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Mentee updated successfully!'), backgroundColor: Colors.green),
            );
          }
          _fetchData();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? 'Failed to update mentee'), backgroundColor: Colors.red),
            );
          }
        }
      } else {
        final data = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Error updating mentee'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showUnassignDialog(Map<String, dynamic> mentee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unassign Mentee', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to unassign ${mentee['fullName']} from ${mentee['assignedTo']['fullName']}?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _unassignMentee(mentee['id']); // Changed from _id to id
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Unassign'),
          ),
        ],
      ),
    );
  }

  void _showDeleteMenteeDialog(Map<String, dynamic> mentee) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
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
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 48,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Delete Mentee?',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 12),
              
              // Mentee Name
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  mentee['fullName'],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Description
              Text(
                'This action cannot be undone. All associated data will be permanently removed.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              
              // Warning Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 20, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'What will be deleted:',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDeleteItem('All call notes and progress'),
                    const SizedBox(height: 8),
                    _buildDeleteItem('Personal information'),
                    const SizedBox(height: 8),
                    _buildDeleteItem('Assignment history'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteMentee(mentee['id']);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red.shade500,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteItem(String text) {
    return Row(
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 16,
          color: Colors.red.shade400,
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
    );
  }

  Future<void> _deleteMentee(String menteeId) async {
    try {
      final token = await secureStorage.read(key: "adminToken");
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
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
                        color: Colors.red.shade400,
                        strokeWidth: 3,
                      ),
                    ),
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 28,
                      color: Colors.red.shade400,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Deleting Mentee...',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final response = await http.delete(
        Uri.parse('$baseUrl/companion-connect/admin/mentees/$menteeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      Navigator.pop(context); // Hide loading

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data['message'] ?? 'Mentee deleted successfully',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          await _fetchMentees(); // Refresh the list
        } else {
          throw Exception(data['message'] ?? 'Failed to delete mentee');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete mentee');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error: $e',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Hover card widget – shows a read-only detail popup on web / desktop hover
// ---------------------------------------------------------------------------
class _MenteeHoverCard extends StatefulWidget {
  final Map<String, dynamic> mentee;
  final VoidCallback onAssign;
  final VoidCallback onUnassign;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const _MenteeHoverCard({
    required this.mentee,
    required this.onAssign,
    required this.onUnassign,
    required this.onView,
    required this.onDelete,
  });

  @override
  State<_MenteeHoverCard> createState() => _MenteeHoverCardState();
}

class _MenteeHoverCardState extends State<_MenteeHoverCard> {
  OverlayEntry? _overlayEntry;
  Timer? _hideTimer;

  // Volunteer fetch state
  bool _fetched = false;
  bool _loadingVolunteer = false;
  Map<String, dynamic>? _volunteerData;

  String? get _volunteerId {
    final a = widget.mentee['assignedTo'];
    if (a == null) return null;
    return a['_id']?.toString() ?? a['id']?.toString();
  }

  Future<void> _fetchVolunteerDetails() async {
    final vid = _volunteerId;
    if (vid == null || _fetched) return;
    _fetched = true;
    if (mounted) setState(() => _loadingVolunteer = true);
    _overlayEntry?.markNeedsBuild();
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'adminToken');
      final response = await http.get(
        Uri.parse('${ApiConfig.apiUrl}/companion-connect/admin/volunteers/$vid/mentee'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && mounted) {
          _volunteerData = data['volunteer'] as Map<String, dynamic>?;
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _loadingVolunteer = false);
      _overlayEntry?.markNeedsBuild();
    }
  }

  bool get _isDesktopOrWeb {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  void _showOverlayAt(Offset globalPosition) {
    if (!_isDesktopOrWeb) return;
    _hideTimer?.cancel();
    if (_overlayEntry != null) return;

    const double popupWidth = 300;
    const double popupMaxHeight = 560;
    final screenSize = MediaQuery.of(context).size;

    double left = globalPosition.dx + 16;
    double top = globalPosition.dy - 20;

    if (left + popupWidth > screenSize.width - 8) {
      left = globalPosition.dx - popupWidth - 16;
    }
    if (top + popupMaxHeight > screenSize.height - 8) {
      top = screenSize.height - popupMaxHeight - 8;
    }
    if (top < 8) top = 8;
    if (left < 8) left = 8;

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: left,
        top: top,
        child: Material(
          color: Colors.transparent,
          child: MouseRegion(
            onEnter: (_) => _cancelHide(),
            onExit: (_) => _scheduleHide(),
            child: _buildPopup(),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    _fetchVolunteerDetails();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 150), _removeOverlay);
  }

  void _cancelHide() {
    _hideTimer?.cancel();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  Widget _buildPopup() {
    final mentee = widget.mentee;
    final isAssigned = mentee['assignedTo'] != null;
    final volunteerName = isAssigned ? (mentee['assignedTo']['fullName'] ?? 'Unknown') : null;
    final status = mentee['status'] ?? 'active';
    final currentCell = mentee['currentCell'] ?? 1;
    final dob = mentee['dob'] != null
        ? mentee['dob'].toString().substring(
            0,
            mentee['dob'].toString().length >= 10 ? 10 : mentee['dob'].toString().length,
          )
        : 'N/A';

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 290,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  child: mentee['photoUrl'] != null &&
                          mentee['photoUrl'].toString().isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            mentee['photoUrl'],
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                color: AppColors.primaryBlue,
                                size: 20),
                          ),
                        )
                      : Icon(Icons.person,
                          color: AppColors.primaryBlue, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mentee['fullName'] ?? 'Unknown',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: status == 'active'
                              ? AppColors.accentGreen.withOpacity(0.15)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: status == 'active'
                                ? AppColors.accentGreen
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Cell $currentCell',
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 10),
            // ── Details ─────────────────────────────────────────────────────
            _popupRow(Icons.cake_outlined, 'Age',
                '${mentee['age'] ?? 'N/A'}'),
            _popupRow(
                Icons.calendar_today_outlined, 'Date of Birth', dob),
            _popupRow(Icons.school_outlined, 'Grade',
                mentee['grade'] ?? 'N/A'),
            _popupRow(
                Icons.wc_outlined, 'Gender', mentee['gender'] ?? 'N/A'),
            _popupRow(Icons.phone_outlined, 'Phone',
                mentee['phone'] ?? 'N/A'),
            _popupRow(Icons.contact_phone_outlined, 'Point of Contact',
                mentee['pointOfContact'] ?? 'N/A'),
            const SizedBox(height: 8),
            // ── Assignment badge ────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isAssigned
                    ? AppColors.accentGreen.withOpacity(0.08)
                    : AppColors.accentOrange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isAssigned
                      ? AppColors.accentGreen.withOpacity(0.35)
                      : AppColors.accentOrange.withOpacity(0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isAssigned
                        ? Icons.link_rounded
                        : Icons.link_off_rounded,
                    size: 14,
                    color: isAssigned
                        ? AppColors.accentGreen
                        : AppColors.accentOrange,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isAssigned
                          ? 'Assigned to $volunteerName'
                          : 'Not assigned to any volunteer',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isAssigned
                            ? AppColors.accentGreen
                            : AppColors.accentOrange,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // ── Notes ───────────────────────────────────────────────────────
            if (mentee['notes'] != null &&
                mentee['notes'].toString().isNotEmpty) ...([
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notes',
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600)),
                    const SizedBox(height: 3),
                    Text(
                      mentee['notes'].toString(),
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.grey.shade800),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ]),
            // ── Volunteer Section ────────────────────────────────────────────
            if (isAssigned) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.volunteer_activism, size: 13,
                      color: AppColors.primaryBlue),
                  const SizedBox(width: 5),
                  Text('Assigned Volunteer',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue)),
                ],
              ),
              const SizedBox(height: 6),
              if (_loadingVolunteer)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryBlue),
                    ),
                  ),
                )
              else if (_volunteerData != null) ...[
                _popupRow(Icons.person_outline, 'Name',
                    _volunteerData!['fullName'] ?? 'N/A'),
                _popupRow(Icons.phone_outlined, 'Phone',
                    _volunteerData!['phone'] ?? 'N/A'),
                _popupRow(Icons.badge_outlined, 'Code',
                    _volunteerData!['volunteerCode'] ?? 'N/A'),
                if (_volunteerData!['dob'] != null)
                  _popupRow(
                    Icons.calendar_today_outlined,
                    'DOB',
                    _volunteerData!['dob'].toString().length >= 10
                        ? _volunteerData!['dob'].toString().substring(0, 10)
                        : _volunteerData!['dob'].toString(),
                  ),
                _popupRow(
                  Icons.circle,
                  'Status',
                  (_volunteerData!['approvalStatus'] ??
                          _volunteerData!['status'] ??
                          'active')
                      .toString()
                      .toUpperCase(),
                ),
              ] else
                Text('Volunteer details unavailable',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey.shade500)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _popupRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Text('$label: ',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.grey.shade500)),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mentee = widget.mentee;
    final isAssigned = mentee['assignedTo'] != null;
    final volunteerName =
        isAssigned ? mentee['assignedTo']['fullName'] : null;
    final status = mentee['status'] ?? 'active';
    final currentCell = mentee['currentCell'] ?? 1;

    final card = Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  child: mentee['photoUrl'] != null &&
                          mentee['photoUrl'].toString().isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            mentee['photoUrl'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.person,
                                    color: AppColors.primaryBlue, size: 30),
                          ),
                        )
                      : Icon(Icons.person,
                          color: AppColors.primaryBlue, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mentee['fullName'] ?? 'Unknown',
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.cake,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Age: ${mentee['age'] ?? 'N/A'}',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: status == 'active'
                                  ? AppColors.accentGreen.withOpacity(0.1)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: status == 'active'
                                    ? AppColors.accentGreen
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Cell $currentCell',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAssigned
                    ? AppColors.accentGreen.withOpacity(0.1)
                    : AppColors.accentOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isAssigned
                      ? AppColors.accentGreen.withOpacity(0.3)
                      : AppColors.accentOrange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isAssigned ? Icons.check_circle : Icons.warning,
                    size: 16,
                    color: isAssigned
                        ? AppColors.accentGreen
                        : AppColors.accentOrange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAssigned
                          ? 'Assigned to: $volunteerName'
                          : 'Not assigned to any volunteer',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isAssigned
                            ? AppColors.accentGreen
                            : AppColors.accentOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isAssigned)
                  TextButton.icon(
                    onPressed: widget.onUnassign,
                    icon: Icon(Icons.link_off, size: 16),
                    label: Text('Unassign'),
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                if (!isAssigned)
                  ElevatedButton.icon(
                    onPressed: widget.onAssign,
                    icon: Icon(Icons.person_add, size: 16),
                    label: Text('Assign'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: widget.onView,
                  icon: Icon(Icons.visibility, size: 16),
                  label: Text('View'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.onDelete,
                  icon: Icon(Icons.delete_outline, size: 20),
                  color: Colors.red,
                  tooltip: 'Delete Mentee',
                  style: IconButton.styleFrom(
                      backgroundColor: Colors.red.shade50),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!_isDesktopOrWeb) return card;

    return MouseRegion(
      onEnter: (event) => _showOverlayAt(event.position),
      onExit: (_) => _scheduleHide(),
      child: card,
    );
  }
}
