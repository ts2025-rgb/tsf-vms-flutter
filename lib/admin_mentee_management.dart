import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'create_mentee_page.dart';

class AdminMenteeManagementPage extends StatefulWidget {
  const AdminMenteeManagementPage({super.key});

  @override
  State<AdminMenteeManagementPage> createState() => _AdminMenteeManagementPageState();
}

class _AdminMenteeManagementPageState extends State<AdminMenteeManagementPage> {
  final String baseUrl = "https://shrew-concrete-cobra.ngrok-free.app/api";
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  
  List<dynamic> _mentees = [];
  List<dynamic> _volunteers = [];
  List<dynamic> _programs = [];
  String? _companionConnectProgramId;
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
              _companionConnectProgramId = ccProgram['id']; // Changed from _id to id
              print('✅ Found Companion Connect ID: $_companionConnectProgramId');
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
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            // Filter only approved volunteers with Companion Connect program
            _volunteers = (data['volunteers'] as List).where((v) {
              return v['approvalStatus'] == 'approved' &&
                     v['interestedPrograms'] != null &&
                     (v['interestedPrograms'] as List).isNotEmpty;
            }).toList();
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
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to assign mentee'), backgroundColor: Colors.red),
        );
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
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
          ? Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
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
          if (_companionConnectProgramId == null) {
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
                companionConnectProgramId: _companionConnectProgramId!,
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
        backgroundColor: Color(0xFF6366F1),
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
                backgroundColor: Color(0xFF6366F1),
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
              ? LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])
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
                color: isSelected ? Colors.white : Color(0xFF6366F1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final assignedCount = _mentees.where((m) => m['assignedTo'] != null).length;
    final activeCount = _mentees.where((m) => m['status'] == 'active').length;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1).withOpacity(0.1), Color(0xFF8B5CF6).withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.people, 'Total', _mentees.length.toString()),
          _buildStatItem(Icons.link, 'Assigned', assignedCount.toString()),
          _buildStatItem(Icons.check_circle, 'Active', activeCount.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF6366F1)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6366F1),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
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
    final isAssigned = mentee['assignedTo'] != null;
    final volunteerName = isAssigned ? mentee['assignedTo']['fullName'] : null;
    final status = mentee['status'] ?? 'active';
    final currentCell = mentee['currentCell'] ?? 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  backgroundColor: Color(0xFF6366F1).withOpacity(0.1),
                  child: mentee['photoUrl'] != null && mentee['photoUrl'].toString().isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            mentee['photoUrl'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: Color(0xFF6366F1), size: 30),
                          ),
                        )
                      : Icon(Icons.person, color: Color(0xFF6366F1), size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mentee['fullName'] ?? 'Unknown',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.cake, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Age: ${mentee['age'] ?? 'N/A'}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: status == 'active' ? Colors.green.shade100 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: status == 'active' ? Colors.green.shade700 : Colors.grey.shade700,
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
                    color: Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Cell $currentCell',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAssigned ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isAssigned ? Colors.green.shade200 : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isAssigned ? Icons.check_circle : Icons.warning,
                    size: 16,
                    color: isAssigned ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAssigned
                          ? 'Assigned to: $volunteerName'
                          : 'Not assigned to any volunteer',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isAssigned ? Colors.green.shade700 : Colors.orange.shade700,
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
                    onPressed: () => _showUnassignDialog(mentee),
                    icon: Icon(Icons.link_off, size: 16),
                    label: Text('Unassign'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                if (!isAssigned)
                  ElevatedButton.icon(
                    onPressed: () => _showAssignDialog(mentee),
                    icon: Icon(Icons.person_add, size: 16),
                    label: Text('Assign'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                    ),
                  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Show mentee details
                  },
                  icon: Icon(Icons.visibility, size: 16),
                  label: Text('View'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignDialog(Map<String, dynamic> mentee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Mentee', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign ${mentee['fullName']} to:',
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: _volunteers.isEmpty
                    ? Center(
                        child: Text(
                          'No approved volunteers found',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _volunteers.length,
                        itemBuilder: (context, index) {
                          final volunteer = _volunteers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: volunteer['photoUrl'] != null
                                  ? NetworkImage(volunteer['photoUrl'])
                                  : null,
                              child: volunteer['photoUrl'] == null
                                  ? Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(
                              volunteer['fullName'] ?? 'Unknown',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              volunteer['email'] ?? '',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _assignMentee(mentee['id'], volunteer['id']); // Changed from _id to id
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
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
}
