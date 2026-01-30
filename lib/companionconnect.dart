import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'config/api_config.dart';
import 'config/app_colors.dart';
import 'screens/volunteer_resources_screen.dart';

class CompanionConnectPage extends StatefulWidget {
  final String programId;
  
  const CompanionConnectPage({super.key, required this.programId});

  @override
  State<CompanionConnectPage> createState() => _CompanionConnectPageState();
}

class _CompanionConnectPageState extends State<CompanionConnectPage> {
  final String baseUrl = ApiConfig.apiUrl;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  
  int _selectedTab = 0;
  Map<String, dynamic>? _menteeData;
  List<dynamic> _callNotes = [];
  bool _loadingMentee = true;
  bool _loadingNotes = false;
  bool _savingNote = false;
  
  final TextEditingController _postCallNoteController = TextEditingController();
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _callDurationController = TextEditingController();
  
  // Detailed Call Log Fields
  final TextEditingController _assistanceRequestOtherDetailController = TextEditingController();
  final TextEditingController _otherTopicController = TextEditingController();
  final TextEditingController _otherFocusAreaController = TextEditingController();
  final TextEditingController _redFlagsController = TextEditingController();
  final TextEditingController _volunteerNoteController = TextEditingController();
  
  double _moodScore = 3.0;
  double _volunteerComfort = 3.0;
  String _mentorHelpfulness = "Yes"; 
  
  List<Map<String, dynamic>> _checklistItems = [];
  
  List<Map<String, dynamic>> _getFocusAreasForCall(int callNumber) {
    if (callNumber <= 2) {
      return [
        {'label': 'Emotional check-in', 'isAchieved': false},
        {'label': 'Getting to know each other', 'isAchieved': false},
        {'label': 'Comfort + trust', 'isAchieved': false},
      ];
    } else if (callNumber <= 4) {
      return [
        {'label': 'Emotional check-in', 'isAchieved': false},
        {'label': 'Routines', 'isAchieved': false},
        {'label': 'Stress', 'isAchieved': false},
        {'label': 'Current concerns', 'isAchieved': false},
      ];
    } else if (callNumber <= 6) {
      return [
        {'label': 'Emotional check-in', 'isAchieved': false},
        {'label': 'School experiences', 'isAchieved': false},
        {'label': 'Challenges', 'isAchieved': false},
        {'label': 'Strengths', 'isAchieved': false},
      ];
    } else if (callNumber <= 8) {
      return [
        {'label': 'Emotional check-in', 'isAchieved': false},
        {'label': 'Strengths', 'isAchieved': false},
        {'label': 'Confidence', 'isAchieved': false},
        {'label': 'School experiences', 'isAchieved': false},
      ];
    } else if (callNumber <= 10) {
      return [
        {'label': 'Emotional check-in', 'isAchieved': false},
        {'label': 'Future hopes', 'isAchieved': false},
        {'label': 'Skills/interests', 'isAchieved': false},
        {'label': 'Meaning-making', 'isAchieved': false},
      ];
    } else {
      return [
        {'label': 'Emotional check-in', 'isAchieved': false},
        {'label': 'Reflection', 'isAchieved': false},
        {'label': 'Looking ahead', 'isAchieved': false},
        {'label': 'Closure', 'isAchieved': false},
      ];
    }
  }
  
  final List<String> _availableTopics = ['Studies', 'Health', 'Family', 'Hobbies', 'Skills', 'Others'];
  final List<String> _selectedTopics = [];
  
  final List<String> _availableAssistanceOptions = ['Emotional Support', 'Safety Concern', 'Academic Support', 'Other Concern', 'Not required'];
  final List<String> _selectedAssistanceRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchMentee();
  }
  
  @override
  void dispose() {
    _postCallNoteController.dispose();
    _queryController.dispose();
    _callDurationController.dispose();
    _assistanceRequestOtherDetailController.dispose();
    _otherTopicController.dispose();
    _otherFocusAreaController.dispose();
    _redFlagsController.dispose();
    _volunteerNoteController.dispose();
    super.dispose();
  }
  
  void _updateChecklistForCurrentCall() {
    final currentCell = _menteeData?['currentCell'] ?? 1;
    setState(() {
      _checklistItems = _getFocusAreasForCall(currentCell);
    });
  }

  Future<void> _fetchMentee() async {
    setState(() => _loadingMentee = true);
    
    try {
      final token = await secureStorage.read(key: "token");
      
      print('🔑 Volunteer Token exists: ${token != null}');
      if (token != null) {
        print('🔑 Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/companion-connect/mentee'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Mentee Response Status: ${response.statusCode}');
      print('📥 Mentee Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['mentee'] != null) {
          setState(() {
            _menteeData = data['mentee'];
            _loadingMentee = false;
          });
          // Update checklist based on current call
          _updateChecklistForCurrentCall();
          // Fetch call notes
          _fetchCallNotes();
        } else {
          setState(() => _loadingMentee = false);
        }
      } else {
        print('❌ Error: ${response.statusCode} - ${response.body}');
        setState(() => _loadingMentee = false);
      }
    } catch (e) {
      print('Error fetching mentee: $e');
      setState(() => _loadingMentee = false);
    }
  }

  Future<void> _fetchCallNotes() async {
    if (_menteeData == null) return;
    
    setState(() => _loadingNotes = true);
    
    try {
      final token = await secureStorage.read(key: "token");
      final menteeId = _menteeData!['_id'];
      
      final response = await http.get(
        Uri.parse('$baseUrl/companion-connect/notes/$menteeId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _callNotes = data['notes'] ?? [];
            _loadingNotes = false;
          });
        }
      } else {
        setState(() => _loadingNotes = false);
      }
    } catch (e) {
      print('Error fetching notes: $e');
      setState(() => _loadingNotes = false);
    }
  }

  Future<void> _saveCallNote() async {
    if (_postCallNoteController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Note must be at least 10 characters long"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _savingNote = true);
    
    try {
      final token = await secureStorage.read(key: "token");
      final menteeId = _menteeData!['_id'];
      final currentCell = _menteeData!['currentCell'] ?? 1;
      
      final hasAssistanceRequest = _selectedAssistanceRequests.isNotEmpty && 
          !(_selectedAssistanceRequests.length == 1 && _selectedAssistanceRequests.contains('Not required'));
      
      // Update Other focus area label with custom text
      final checklistToSend = _checklistItems.map((item) {
        if (item['label'] == 'Other' && _otherFocusAreaController.text.trim().isNotEmpty) {
          return {
            'label': 'Other: ${_otherFocusAreaController.text.trim()}',
            'isAchieved': item['isAchieved'],
          };
        }
        return item;
      }).toList();
      
      final bodyPayload = {
          'menteeId': menteeId,
          'note': _postCallNoteController.text.trim(),
          'cellNumber': currentCell,
          'callDuration': int.tryParse(_callDurationController.text) ?? 0,
          'followUpRequired': hasAssistanceRequest,
          'assistanceRequest': _selectedAssistanceRequests,
          'assistanceRequestOtherDetail': _selectedAssistanceRequests.contains('Other Concern') ? _assistanceRequestOtherDetailController.text.trim() : '',
          'moodScore': _moodScore,
          'checklist': checklistToSend,
          'topics': _selectedTopics,
          'otherTopicDetail': _selectedTopics.contains('Others') ? _otherTopicController.text.trim() : '',
          'mentorHelpfulness': _mentorHelpfulness,
          'redFlags': _redFlagsController.text.trim(),
          'volunteerComfort': _volunteerComfort,
          'volunteerNote': _volunteerNoteController.text.trim(),
      };

      print("📤 SENDING NOTE PAYLOAD: ${json.encode(bodyPayload)}");

      final response = await http.post(
        Uri.parse('$baseUrl/companion-connect/notes'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(bodyPayload),
      );

      setState(() => _savingNote = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Report saved successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          _postCallNoteController.clear();
          _callDurationController.clear();
          _assistanceRequestOtherDetailController.clear();
          _otherTopicController.clear();
          _otherFocusAreaController.clear();
          _redFlagsController.clear();
          _volunteerNoteController.clear();
          setState(() {
             _moodScore = 3.0;
             _volunteerComfort = 3.0;
             _mentorHelpfulness = "Yes";
             _selectedTopics.clear();
             _selectedAssistanceRequests.clear();
             _updateChecklistForCurrentCall(); // Reset checklist to fresh state
          });
          // Refresh notes
          await _fetchCallNotes();
          
          // Auto-advance to next call or mark complete for call 12
          if (currentCell <= 12) {
            await Future.delayed(Duration(milliseconds: 800));
            if (currentCell < 12) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Moving to Call #${currentCell + 1}..."),
                  backgroundColor: AppColors.primaryBlue,
                  duration: Duration(seconds: 2),
                ),
              );
            }
            await Future.delayed(Duration(milliseconds: 500));
            await _advanceProgress();
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save note"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error saving note: $e');
      setState(() => _savingNote = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving note"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _makePhoneCall() async {
    if (_menteeData == null || _menteeData!['phone'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Phone number not available"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final phoneNumber = _menteeData!['phone'].toString().replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not launch phone dialer"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _advanceProgress() async {
    if (_menteeData == null) return;
    
    final currentCell = _menteeData!['currentCell'] ?? 1;
    
    // For call 12, mark as complete and show celebration
    if (currentCell >= 12) {
      try {
        final token = await secureStorage.read(key: "token");
        final menteeId = _menteeData!['_id'];
        
        // Mark call 12 as complete by setting to 13 (indicating all calls done)
        final response = await http.patch(
          Uri.parse('$baseUrl/companion-connect/progress'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'menteeId': menteeId,
            'newCell': 13,
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("🎉 Congratulations! You've completed all 12 calls with your mentee!"),
                backgroundColor: AppColors.accentGreen,
                duration: Duration(seconds: 3),
              ),
            );
            // Refresh mentee data to show completion
            _fetchMentee();
          }
        }
      } catch (e) {
        print('Error marking completion: $e');
      }
      return;
    }

    final newCell = currentCell + 1;
    
    try {
      final token = await secureStorage.read(key: "token");
      final menteeId = _menteeData!['_id'];
      
      final response = await http.patch(
        Uri.parse('$baseUrl/companion-connect/progress'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'menteeId': menteeId,
          'newCell': newCell,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Call #$currentCell marked complete! Moving to Call #$newCell."),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh mentee data
          _fetchMentee();
        }
      }
    } catch (e) {
      print('Error updating progress: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating progress"),
          backgroundColor: Colors.red,
        ),
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
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.people, size: 24),
            ),
            const SizedBox(width: 12),
            Text("Companion Connect", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: _showMenteeProfile,
              borderRadius: BorderRadius.circular(20),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: _menteeData != null && _menteeData!['photoUrl'] != null && _menteeData!['photoUrl'].isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          _menteeData!['photoUrl'],
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.person, size: 20, color: Colors.white);
                          },
                        ),
                      )
                    : Icon(Icons.person, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Mentee Info Card
            _buildMenteeInfoCard(),
            
            // Progress Tracker
            _buildProgressTracker(),
            
            // Focus Areas Guide
            _buildFocusAreasGuide(),
            
            // Log Post Call Note
            _buildPostCallNoteSection(),
            
            // Call History
            // Call History moved to bottom sheet
            
            const SizedBox(height: 80), // Extra space for bottom action bar
          ],
        ),
      ),
      bottomNavigationBar: _menteeData != null ? _buildBottomActionBar() : null,
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Query/Support Button
            Expanded(
              child: _buildActionButton(
                icon: Icons.help_outline,
                label: "Support",
                color: AppColors.accentGreen,
                onTap: () => _showBottomSheet(2),
              ),
            ),
            SizedBox(width: 12),
            // Call Button
            Expanded(
              child: _buildActionButton(
                icon: Icons.phone,
                label: "Call",
                color: AppColors.accentOrange,
                onTap: _makePhoneCall,
              ),
            ),
            SizedBox(width: 12),
            // Resources Button
            Expanded(
              child: _buildActionButton(
                icon: Icons.library_books,
                label: "Resources",
                color: AppColors.secondaryBlue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VolunteerResourcesScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenteeInfoCard() {
    if (_loadingMentee) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
      );
    }

    if (_menteeData == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "No mentee assigned to you yet. Please contact admin.",
                style: GoogleFonts.poppins(color: Colors.orange.shade700),
              ),
            ),
          ],
        ),
      );
    }

    final String menteeName = _menteeData!['fullName'] ?? 'Unknown';
    final int menteeAge = _menteeData!['age'] ?? 0;
    final String gender = _menteeData!['gender'] ?? 'N/A';
    final String phone = _menteeData!['phone'] ?? 'N/A';
    final String region = _menteeData!['region'] ?? 'N/A';
    final String grade = _menteeData!['grade'] ?? 'N/A';
    final String pointOfContact = _menteeData!['pointOfContact'] ?? 'N/A';
    final String assignedDate = _menteeData!['assignedAt'] != null
        ? DateTime.parse(_menteeData!['assignedAt']).toString().substring(0, 10)
        : 'N/A';
    final String photoUrl = _menteeData!['photoUrl'] ?? '';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                child: photoUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          photoUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                             return Icon(Icons.person, color: AppColors.primaryBlue, size: 30);
                          },
                        ),
                      )
                    : Icon(Icons.person, color: AppColors.primaryBlue, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menteeName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Age: $menteeAge years",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.wc, "Gender", gender),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.school_outlined, "Grade", grade),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on_outlined, "Region", region),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.person_outline, "Point of Contact", pointOfContact),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.calendar_today, "Assigned", assignedDate),
          if (_menteeData!['notes'] != null && _menteeData!['notes'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildNotesRow(Icons.notes, "Notes", _menteeData!['notes']),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesRow(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              "$label:",
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressTracker() {
    if (_menteeData == null) return const SizedBox.shrink();

    final int currentCell = _menteeData!['currentCell'] ?? 1;
    final int totalCalls = currentCell <= 12 ? (currentCell + 5 > 12 ? 12 : currentCell + 5) : 12; // Cap at 12 calls

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withOpacity(0.08),
            AppColors.accentGreen.withOpacity(0.06),
            AppColors.accentYellow.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Quest Icon
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(Icons.explore, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              // Quest Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            "🗺️ Epic Journey",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryBlue,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 6),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.accentGreen, AppColors.accentGreen.withOpacity(0.7)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentGreen.withOpacity(0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                "LVL $currentCell",
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.bolt, color: AppColors.accentYellow, size: 14),
                        SizedBox(width: 4),
                        Text(
                          "${(currentCell - 1) * 100} XP",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentOrange,
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(Icons.whatshot, color: Colors.orange, size: 14),
                        SizedBox(width: 4),
                        Text(
                          "${currentCell - 1} Streak",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // XP Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Progress to Next Level",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    "${((currentCell - 1) / totalCalls * 100).toStringAsFixed(0)}%",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: (currentCell - 1) / totalCalls,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accentGreen,
                            AppColors.primaryBlue,
                            AppColors.accentYellow,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          // Complete Quest Button
          if (currentCell < 12)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accentGreen, Colors.green.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGreen.withOpacity(0.4),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _advanceProgress,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, color: Colors.white, size: 24),
                      SizedBox(width: 10),
                      Text(
                        "COMPLETE QUEST & EARN 100 XP",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (currentCell >= 12)
          Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade400, Colors.orange.shade400],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.4),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text(
                  "Journey Complete! 🎉",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Scrollable Adventure Map Trail
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade50.withOpacity(0.5),
                  Colors.green.shade50.withOpacity(0.5),
                  Colors.amber.shade50.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
            ),
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: totalCalls,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                itemBuilder: (context, index) {
                  final callNumber = index + 1;
                  final isCompleted = callNumber < currentCell;
                  final isCurrent = callNumber == currentCell;
                  final isUpcoming = callNumber > currentCell;
                  final isMilestone = callNumber % 5 == 0;
                  
                  return _buildStoryNode(
                    callNumber: callNumber,
                    isCompleted: isCompleted,
                    isCurrent: isCurrent,
                    isUpcoming: isUpcoming,
                    isMilestone: isMilestone,
                    isLast: callNumber == totalCalls,
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          // Achievements Row
          if (currentCell > 3)
            Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accentYellow.withOpacity(0.2), AppColors.accentOrange.withOpacity(0.15)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentOrange.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.workspace_premium, color: AppColors.accentOrange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "🏆 Achievement Unlocked: ",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  Text(
                    currentCell > 10 ? "Legendary Mentor!" : currentCell > 5 ? "Master Caller!" : "Rising Star!",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentOrange,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStoryLegend(AppColors.accentGreen, "✓", "Conquered"),
              SizedBox(width: 20),
              _buildStoryLegend(AppColors.primaryBlue, "⚡", "Active"),
              SizedBox(width: 20),
              _buildStoryLegend(Colors.grey.shade400, "🔒", "Locked"),
            ],
          ),
          SizedBox(height: 12),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryBlue.withOpacity(0.15), AppColors.secondaryBlue.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swipe, color: AppColors.primaryBlue, size: 16),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "Swipe to explore your epic adventure path!",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryNode({
    required int callNumber,
    required bool isCompleted,
    required bool isCurrent,
    required bool isUpcoming,
    required bool isMilestone,
    required bool isLast,
  }) {
    String emoji;
    String rewardText;
    Color nodeColor;
    Color glowColor;
    
    if (isCompleted) {
      emoji = "✅";
      rewardText = "+100 XP";
      nodeColor = AppColors.accentGreen;
      glowColor = AppColors.accentGreen;
    } else if (isCurrent) {
      emoji = "⚡";
      rewardText = "NOW!";
      nodeColor = AppColors.primaryBlue;
      glowColor = AppColors.primaryBlue;
    } else {
      emoji = "🔒";
      rewardText = "Locked";
      nodeColor = Colors.grey.shade400;
      glowColor = Colors.grey.shade400;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: isMilestone ? 120 : 110,
          height: isMilestone ? 220 : 170,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Milestone Badge
              if (isMilestone)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  margin: EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.accentYellow, AppColors.accentOrange],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentOrange.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        "EPIC",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              // Story Node with pulse animation
              GestureDetector(
                onTap: isCompleted ? () {
                  print("👆 Tapped on completed Call #$callNumber");
                  _showCallDetails(callNumber);
                } : null,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow ring for current quest
                    if (isCurrent)
                      Container(
                        width: isMilestone ? 100 : 90,
                        height: isMilestone ? 100 : 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              glowColor.withOpacity(0.4),
                              glowColor.withOpacity(0.2),
                              glowColor.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    // Main quest node
                    Container(
                      width: isMilestone ? 85 : 75,
                      height: isMilestone ? 85 : 75,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isUpcoming
                              ? [nodeColor, nodeColor]
                              : [nodeColor, nodeColor.withOpacity(0.75)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withOpacity(isCurrent ? 0.6 : 0.25),
                            blurRadius: isCurrent ? 20 : 10,
                            spreadRadius: isCurrent ? 4 : 2,
                            offset: Offset(0, isCurrent ? 6 : 3),
                          ),
                        ],
                        border: Border.all(
                          color: isCurrent ? Colors.white : Colors.white.withOpacity(0.4),
                          width: isCurrent ? 5 : 3,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            emoji,
                            style: TextStyle(fontSize: isMilestone ? 32 : 26),
                          ),
                          SizedBox(height: 3),
                          Text(
                            "#$callNumber",
                            style: GoogleFonts.poppins(
                              fontSize: isMilestone ? 16 : 14,
                              fontWeight: FontWeight.w900,
                              color: isUpcoming ? Colors.white.withOpacity(0.6) : Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Reward badge
                    if (isCompleted || isCurrent)
                      Positioned(
                        bottom: isMilestone ? -5 : -8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isCompleted
                                  ? [AppColors.accentGreen, Colors.green.shade600]
                                  : [AppColors.accentYellow, AppColors.accentOrange],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            rewardText,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              // Status Label with icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCompleted)
                    Icon(Icons.check_circle, color: AppColors.accentGreen, size: 12),
                  if (isCurrent)
                    Icon(Icons.play_circle_filled, color: AppColors.primaryBlue, size: 12),
                  if (isUpcoming)
                    Icon(Icons.lock, color: Colors.grey.shade500, size: 12),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      isCompleted ? "Victory!" : isCurrent ? "In Battle" : "Upcoming",
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isCompleted
                            ? AppColors.accentGreen
                            : isCurrent
                                ? AppColors.primaryBlue
                                : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Animated connecting trail (scrolls with nodes!)
        if (!isLast)
          Container(
            width: 45,
            height: 80,
            child: Stack(
              children: [
                // Main trail path
                Positioned(
                  left: 0,
                  right: 0,
                  top: 35,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCompleted
                            ? [AppColors.accentGreen, AppColors.accentGreen.withOpacity(0.6)]
                            : [Colors.grey.shade300, Colors.grey.shade200],
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: isCompleted ? [
                        BoxShadow(
                          color: AppColors.accentGreen.withOpacity(0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ] : null,
                    ),
                  ),
                ),
                // Decorative dots on trail
                Positioned(
                  left: 10,
                  top: 32,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.white : Colors.grey.shade400,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 32,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.white : Colors.grey.shade400,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                // Arrow indicator for completed trails
                if (isCompleted)
                  Positioned(
                    right: 5,
                    top: 30,
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.accentGreen,
                      size: 12,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStoryLegend(Color color, String emoji, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: TextStyle(fontSize: 14)),
        SizedBox(width: 4),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildCellIndicator(int cellNumber, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isActive
                ? AppColors.primaryGradient
                : null,
            color: isActive ? null : Colors.grey.shade300,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              "$cellNumber",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive ? AppColors.primaryBlue : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildArrow() {
    return Icon(
      Icons.arrow_forward,
      color: Colors.grey.shade400,
      size: 20,
    );
  }
  
  Widget _buildFocusAreasGuide() {
    if (_menteeData == null) return const SizedBox.shrink();
    
    final currentCell = _menteeData!['currentCell'] ?? 1;
    final focusAreas = _getFocusAreasForCall(currentCell);
    
    String phaseTitle;
    String phaseDescription;
    Color phaseColor;
    IconData phaseIcon;
    
    if (currentCell <= 2) {
      phaseTitle = "Building Connection";
      phaseDescription = "Focus on creating a safe, comfortable space";
      phaseColor = AppColors.accentGreen;
      phaseIcon = Icons.handshake;
    } else if (currentCell <= 4) {
      phaseTitle = "Understanding Daily Life";
      phaseDescription = "Explore routines, stress, and current concerns";
      phaseColor = AppColors.primaryBlue;
      phaseIcon = Icons.calendar_today;
    } else if (currentCell <= 6) {
      phaseTitle = "School & Growth";
      phaseDescription = "Discuss academic experiences and strengths";
      phaseColor = AppColors.accentOrange;
      phaseIcon = Icons.school;
    } else if (currentCell <= 8) {
      phaseTitle = "Building Confidence";
      phaseDescription = "Reinforce strengths and self-belief";
      phaseColor = AppColors.accentYellow;
      phaseIcon = Icons.star;
    } else if (currentCell <= 10) {
      phaseTitle = "Future Aspirations";
      phaseDescription = "Explore hopes, interests, and dreams";
      phaseColor = Colors.purple.shade400;
      phaseIcon = Icons.rocket_launch;
    } else {
      phaseTitle = "Reflection & Closure";
      phaseDescription = "Look back on growth and plan for the future";
      phaseColor = Colors.pink.shade400;
      phaseIcon = Icons.favorite;
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            phaseColor.withOpacity(0.1),
            phaseColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: phaseColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: phaseColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: phaseColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(phaseIcon, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phaseTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: phaseColor,
                      ),
                    ),
                    Text(
                      phaseDescription,
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
          Text(
            "Suggested Focus Areas:",
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: focusAreas.map((area) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: phaseColor.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: phaseColor,
                    ),
                    SizedBox(width: 6),
                    Text(
                      area['label'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, size: 16, color: Colors.blue.shade700),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "These are conversation guides, not strict requirements. Follow the mentee's lead.",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCallNoteSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
              Icon(Icons.edit_note, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                "Log Report for Call #${_menteeData?['currentCell'] ?? 1}",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(),
          const SizedBox(height: 16),

          // 1. Mood Score
          Text("Mentee's Mood", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Slider(
                      value: _moodScore,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: "$_moodScore",
                      activeColor: AppColors.primaryBlue,
                      onChanged: (v) => setState(() => _moodScore = v),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Bad", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600)),
                          Text("Low", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600)),
                          Text("Neutral", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600)),
                          Text("Good", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600)),
                          Text("Excited", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _getMoodEmoji(_moodScore),
                style: TextStyle(fontSize: 28),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Checklist
          Row(
            children: [
              Expanded(
                child: Text("Which focus areas were covered?", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: "Check the topics you discussed during this call",
                child: Icon(Icons.info_outline, size: 18, color: AppColors.primaryBlue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_checklistItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                "Loading focus areas...",
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
            ),
          ..._checklistItems.map((item) {
             return CheckboxListTile(
                title: Text(item['label'] == 'Other' ? 'Other' : item['label'], style: GoogleFonts.poppins(fontSize: 13)),
                value: item['isAchieved'],
                activeColor: AppColors.primaryBlue,
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) {
                  setState(() {
                    if (item['label'] == 'Other' && v == false) {
                      // If unchecking "Other", remove it from the list
                      _checklistItems.removeWhere((i) => i['label'] == 'Other');
                      _otherFocusAreaController.clear();
                    } else {
                      item['isAchieved'] = v;
                    }
                  });
                },
             );
          }).toList(),
          if (!_checklistItems.any((item) => item['label'] == 'Other'))
            CheckboxListTile(
              title: Text('Other', style: GoogleFonts.poppins(fontSize: 13)),
              value: false,
              activeColor: AppColors.primaryBlue,
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) {
                if (v == true) {
                  setState(() {
                    _checklistItems.add({'label': 'Other', 'isAchieved': true});
                  });
                }
              },
            ),
          if (_checklistItems.any((item) => item['label'] == 'Other' && item['isAchieved'] == true)) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _otherFocusAreaController,
              decoration: InputDecoration(
                hintText: "Specify other focus area...",
                hintStyle: GoogleFonts.poppins(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),

          // 3. Topics
          Text("Topics Covered", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTopics.map((topic) {
              final isSelected = _selectedTopics.contains(topic);
              return FilterChip(
                label: Text(topic),
                selected: isSelected,
                selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                checkmarkColor: AppColors.primaryBlue,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isSelected ? AppColors.primaryBlue : Colors.black87,
                ),
                onSelected: (v) {
                  setState(() {
                    if (v) _selectedTopics.add(topic);
                    else _selectedTopics.remove(topic);
                  });
                },
              );
            }).toList(),
          ),
          if (_selectedTopics.contains('Others')) ...[
             const SizedBox(height: 8),
             TextField(
               controller: _otherTopicController,
               decoration: InputDecoration(
                 hintText: "Specify other topics details...",
                 hintStyle: GoogleFonts.poppins(fontSize: 12),
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                 contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
               ),
               style: GoogleFonts.poppins(fontSize: 13),
             ),
          ],
          const SizedBox(height: 16),

          // 4. Observations (Main Note)
          Text("Observations / Notes", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _postCallNoteController,
            maxLines: 4,
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              hintText: "Brief notes on themes discussed or noteworthy moments. Avoid judgment or diagnosis.",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),

          // 5. Assistance Request
          Text("Assistance Needed / Follow-up", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableAssistanceOptions.map((option) {
              final isSelected = _selectedAssistanceRequests.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                checkmarkColor: AppColors.primaryBlue,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isSelected ? AppColors.primaryBlue : Colors.black87,
                ),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedAssistanceRequests.add(option);
                    } else {
                      _selectedAssistanceRequests.remove(option);
                    }
                  });
                },
              );
            }).toList(),
          ),
          if (_selectedAssistanceRequests.contains('Other Concern')) ...[
             const SizedBox(height: 8),
             TextField(
               controller: _assistanceRequestOtherDetailController,
               decoration: InputDecoration(
                 hintText: "Please specify other concern details...",
                 hintStyle: GoogleFonts.poppins(fontSize: 12),
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                 contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
               ),
               style: GoogleFonts.poppins(fontSize: 13),
             ),
          ],
          const SizedBox(height: 16),
          
          // 6. Mentor Helpfulness
          Text("Did this conversation feel meaningful??", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
          Row(
            children: ["Yes", "Neutral", "No"].map((opt) => 
               Expanded(
                 child: RadioListTile<String>(
                   title: Text(opt, style: GoogleFonts.poppins(fontSize: 13)),
                   value: opt,
                   groupValue: _mentorHelpfulness,
                   activeColor: AppColors.primaryBlue,
                   contentPadding: EdgeInsets.zero,
                   onChanged: (v) => setState(() => _mentorHelpfulness = v!),
                 ),
               )
            ).toList(),
          ),
          
          // 7. Red Flags
          const SizedBox(height: 8),
          Text("Red Flags (Optional)", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.red)),
          const SizedBox(height: 8),
          TextField(
            controller: _redFlagsController,
            maxLines: 4,
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              hintText: "Use only if something felt concerning or unsafe.Briefly write what raised concern.",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade200)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 20),
          
          // 8. Duration
          TextField(
            controller: _callDurationController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              labelText: "Call Duration (minutes)",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: Icon(Icons.timer, color: Colors.grey),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 9. Volunteer Comfort Check-in
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite_outline, color: AppColors.primaryBlue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Your Comfort Check-in (Optional)",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.primaryBlue),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "How comfortable did you feel during this call?",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    Slider(
                      value: _volunteerComfort,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: "${_volunteerComfort.toInt()}",
                      activeColor: AppColors.primaryBlue,
                      onChanged: (v) => setState(() => _volunteerComfort = v),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Uncomfortable", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600)),
                          Text("Neutral", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600)),
                          Text("Very Comfortable", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Personal Notes (For your reference only)",
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _volunteerNoteController,
                  maxLines: 3,
                  maxLength: 1000,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Any personal reflections, challenges, or learnings from this call...",
                    hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(12),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: ElevatedButton.icon(
                onPressed: _savingNote || _menteeData == null ? null : _saveCallNote,
                icon: _savingNote
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : Icon(Icons.save, color: Colors.white),
                label: Text(
                  _savingNote ? "Saving Report..." : "Submit Report",
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMoodEmoji(double score) {
    if (score >= 4.5) return "🤩";
    if (score >= 3.5) return "🙂";
    if (score >= 2.5) return "😐";
    if (score >= 1.5) return "😟";
    return "😭";
  }

  Widget _buildCallHistory() {
    if (_loadingNotes) {
      return Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
      );
    }
    
    if (_callNotes.isEmpty) return SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              "Call History Logs",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.dark2,
              ),
            ),
          ),
          ..._callNotes.map((note) => _buildNoteCard(note)).toList(),
        ],
      ),
    );
  }

  Widget _buildNoteCard(dynamic note) {
    final callNum = note['cellNumber'] != null ? "${note['cellNumber']}" : "?";
    final content = note['note'] ?? '';
    
    String dateStr = "";
    if (note['createdAt'] != null) {
      try {
        final date = DateTime.parse(note['createdAt']);
        dateStr = "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
      } catch (e) {}
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showNoteDetails(note),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Call #$callNum",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      if (note['callDuration'] != null)
                      Text(
                        "${note['callDuration']} mins",
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  Text(
                    dateStr,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade800),
              ),
              SizedBox(height: 8),
              if (note['redFlags'] != null && note['redFlags'].toString().isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Icon(Icons.flag, color: Colors.red, size: 12),
                       SizedBox(width: 4),
                       Text("Red Flags Reported", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                     ],
                  ),
                ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("View Details", style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.w500)),
                  Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.primaryBlue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoteDetails(dynamic note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  ),
                  SizedBox(height: 20),
                  Text("Call #${note['cellNumber']} Details", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                  Divider(),
                  
                  // Mood
                  if (note['moodScore'] != null) ...[
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text("Mood: ", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        Text(_getMoodEmoji((note['moodScore'] is int ? (note['moodScore'] as int).toDouble() : note['moodScore']) ?? 3.0), style: TextStyle(fontSize: 24)),
                        SizedBox(width: 8),
                        Text("(${note['moodScore']}/5)", style: GoogleFonts.poppins(color: Colors.grey)),
                      ],
                    ),
                  ],

                  // Topics
                  if (note['topics'] != null && (note['topics'] as List).isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text("Topics Covered:", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: (note['topics'] as List).map((t) => Chip(
                        label: Text(t.toString(), style: GoogleFonts.poppins(fontSize: 12)),
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                      )).toList(),
                    ),
                    if (note['otherTopicDetail'] != null && note['otherTopicDetail'].toString().isNotEmpty)
                       Padding(
                         padding: EdgeInsets.only(top: 4),
                         child: Text("Other: ${note['otherTopicDetail']}", style: GoogleFonts.poppins(fontSize: 12, fontStyle: FontStyle.italic)),
                       ),
                  ],

                  // Checklist
                  if (note['checklist'] != null && (note['checklist'] as List).isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text("Discussion Checklist:", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ... (note['checklist'] as List).map((item) {
                       final achieved = item['isAchieved'] == true;
                       return ListTile(
                         visualDensity: VisualDensity.compact,
                         leading: Icon(achieved ? Icons.check_circle : Icons.cancel_outlined, color: achieved ? Colors.green : Colors.grey, size: 20),
                         title: Text(item['label'] ?? '', style: GoogleFonts.poppins(fontSize: 13, decoration: achieved ? null : TextDecoration.lineThrough, color: achieved ? Colors.black : Colors.grey)),
                       );
                    }).toList(),
                  ],

                  // Observation
                  SizedBox(height: 16),
                  Text("Observations:", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(note['note'] ?? 'No observations.', style: GoogleFonts.poppins(fontSize: 14)),
                  ),

                  // Assistance
                  if (note['assistanceRequest'] != null && note['assistanceRequest'].toString().isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text("Assistance Requested:", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.orange)),
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade100)),
                      child: Text(note['assistanceRequest'], style: GoogleFonts.poppins(fontSize: 13)),
                    ),
                  ],

                  // Red Flags
                  if (note['redFlags'] != null && note['redFlags'].toString().isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text("RED FLAGS:", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.red)),
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade100)),
                      child: Text(note['redFlags'], style: GoogleFonts.poppins(fontSize: 13, color: Colors.red.shade900)),
                    ),
                  ],
                  
                  // Helpfulness
                   if (note['mentorHelpfulness'] != null) ...[
                     SizedBox(height: 16),
                     Row(children: [
                       Text("Was helpful? ", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                       Text(note['mentorHelpfulness'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                     ]),
                   ],
                   
                   SizedBox(height: 30),
                   SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pop(context), child: Text("Close"))),
                ],
              ),
            );
          },
        );
      }
    );
  }


  void _showBottomSheet(int type) {
    if (type == 2) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => VolunteerQuerySheet(
          menteeId: _menteeData?['id'] ?? _menteeData?['_id'],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content based on type
              Expanded(
                child: type == 0
                    ? _buildResourcesContent()
                    : type == 3
                        ? _buildHistorySheetContent()
                        : _buildCallContent(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistorySheetContent() {
    if (_loadingNotes) {
      return Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
    }
    
    if (_callNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 48, color: Colors.grey.shade300),
            SizedBox(height: 16),
            Text("No call history logs yet", style: GoogleFonts.poppins(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          "Call History Logs",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ..._callNotes.map((note) => _buildNoteCard(note)).toList(),
      ],
    );
  }

  void _showCallDetails(int callNumber) {
    print("🔍 _showCallDetails called for Call #$callNumber");
    print("🔍 Total notes available: ${_callNotes.length}");
    print("🔍 Call notes data: ${_callNotes.map((n) => 'Call #${n['cellNumber']}').join(', ')}");
    
    final callNote = _callNotes.firstWhere(
      (note) => note['cellNumber'] == callNumber,
      orElse: () => null,
    );
    
    if (callNote == null) {
      print("❌ No call note found for Call #$callNumber");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No details found for Call #$callNumber"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    print("✅ Found call note for Call #$callNumber: ${callNote.keys.toList()}");
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.history, color: Colors.white, size: 24),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Call #$callNumber Report",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "Read-only view",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.all(20),
                      children: [
                        _buildReadOnlyField("Date", _formatDate(callNote['createdAt'])),
                        SizedBox(height: 16),
                        _buildReadOnlyField("Call Duration", "${callNote['callDuration'] ?? 0} minutes"),
                        SizedBox(height: 16),
                        _buildReadOnlyField("Mentee's Mood", "${callNote['moodScore'] ?? 'N/A'} ${_getMoodEmoji(callNote['moodScore']?.toDouble() ?? 3.0)}"),
                        SizedBox(height: 16),
                        if (callNote['checklist'] != null && (callNote['checklist'] as List).isNotEmpty) ...[
                          _buildReadOnlySection(
                            "Focus Areas Covered",
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: (callNote['checklist'] as List)
                                  .where((item) => item['isAchieved'] == true)
                                  .map((item) => Padding(
                                        padding: EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: AppColors.accentGreen, size: 18),
                                            SizedBox(width: 8),
                                            Text(
                                              item['label'] ?? '',
                                              style: GoogleFonts.poppins(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                        if (callNote['topics'] != null && (callNote['topics'] as List).isNotEmpty) ...[
                          _buildReadOnlySection(
                            "Topics Covered",
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (callNote['topics'] as List)
                                  .map((topic) => Chip(
                                        label: Text(
                                          topic,
                                          style: GoogleFonts.poppins(fontSize: 12),
                                        ),
                                        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                                      ))
                                  .toList(),
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                        if (callNote['otherTopicDetail'] != null && callNote['otherTopicDetail'].toString().trim().isNotEmpty) ...[
                          _buildReadOnlyField("Other Topic Details", callNote['otherTopicDetail']),
                          SizedBox(height: 16),
                        ],
                        _buildReadOnlyField("Observations / Notes", callNote['note'] ?? 'No notes'),
                        SizedBox(height: 16),
                        if (callNote['assistanceRequest'] != null && (callNote['assistanceRequest'] as List).isNotEmpty) ...[
                          _buildReadOnlySection(
                            "Assistance Needed",
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (callNote['assistanceRequest'] as List)
                                  .map((request) => Chip(
                                        label: Text(
                                          request,
                                          style: GoogleFonts.poppins(fontSize: 12),
                                        ),
                                        backgroundColor: Colors.orange.withOpacity(0.1),
                                      ))
                                  .toList(),
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                        if (callNote['assistanceRequestOtherDetail'] != null && callNote['assistanceRequestOtherDetail'].toString().trim().isNotEmpty) ...[
                          _buildReadOnlyField("Other Concern Details", callNote['assistanceRequestOtherDetail']),
                          SizedBox(height: 16),
                        ],
                        _buildReadOnlyField("Conversation Meaningful?", callNote['mentorHelpfulness'] ?? 'N/A'),
                        SizedBox(height: 16),
                        if (callNote['redFlags'] != null && callNote['redFlags'].toString().trim().isNotEmpty) ...[
                          Container(
                            padding: EdgeInsets.all(12),
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
                                    Icon(Icons.warning, color: Colors.red, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      "Red Flags",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  callNote['redFlags'],
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                        if (callNote['volunteerComfort'] != null) ...[
                          _buildReadOnlyField("Your Comfort Level", "${callNote['volunteerComfort']}/5"),
                          SizedBox(height: 16),
                        ],
                        if (callNote['volunteerNote'] != null && callNote['volunteerNote'].toString().trim().isNotEmpty) ...[
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.favorite, color: AppColors.primaryBlue, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      "Your Personal Notes",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  callNote['volunteerNote'],
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
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
  
  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
      ],
    );
  }
  
  Widget _buildReadOnlySection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        content,
      ],
    );
  }
  
  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return 'N/A';
    }
  }

  void _showMenteeProfile() {
    if (_menteeData == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Container(width: 40, height: 4, margin: EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
               GestureDetector(
                 onTap: () {
                    if (_menteeData!['photoUrl'] != null && _menteeData!['photoUrl'].toString().isNotEmpty) {
                       showDialog(
                         context: context, 
                         builder: (context) => Dialog(
                           backgroundColor: Colors.transparent,
                           child: InteractiveViewer(
                             panEnabled: true, 
                             boundaryMargin: EdgeInsets.all(20),
                             minScale: 0.5,
                             maxScale: 4, 
                             child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_menteeData!['photoUrl']))
                           ),
                         ),
                       );
                    }
                 },
                 child: CircleAvatar(
                   radius: 50,
                   backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                   child: _menteeData!['photoUrl'] != null && _menteeData!['photoUrl'].toString().isNotEmpty 
                      ? ClipOval(
                          child: Image.network(
                            _menteeData!['photoUrl'],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                               return Icon(Icons.person, size: 50, color: AppColors.primaryBlue);
                            },
                          ),
                        ) 
                      : Icon(Icons.person, size: 50, color: AppColors.primaryBlue),
                 ),
               ),
               SizedBox(height: 16),
               Text("${_menteeData!['fullName']}", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
               Container(
                 margin: EdgeInsets.symmetric(vertical: 4),
                 padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                 decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                 child: Text("Active Mentee", style: GoogleFonts.poppins(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500)),
               ),
               SizedBox(height: 24),
               _buildProfileDetailRow(Icons.cake, "Age / Gender", "${_menteeData!['age']} years • ${_menteeData!['gender'] ?? 'N/A'}"),
               _buildProfileDetailRow(Icons.school_outlined, "Grade", "${_menteeData!['grade'] ?? 'N/A'}"),
               _buildProfileDetailRow(Icons.location_on, "Region", "${_menteeData!['region'] ?? 'N/A'}"),
               _buildProfileDetailRow(Icons.person_outline, "Point of Contact", "${_menteeData!['pointOfContact'] ?? 'N/A'}"),
               _buildProfileDetailRow(Icons.school, "Program", "${_menteeData!['program']?['name'] ?? 'N/A'}"),
               _buildProfileDetailRow(Icons.calendar_today, "Assigned On", "${_menteeData!['assignedAt']?.substring(0,10) ?? 'N/A'}"),
                 
               SizedBox(height: 24),
               SizedBox(
                 width: double.infinity, 
                 child: ElevatedButton(
                   onPressed: () => Navigator.pop(context), 
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.grey.shade100,
                     foregroundColor: Colors.black87,
                     elevation: 0,
                     padding: EdgeInsets.symmetric(vertical: 16),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                   ),
                   child: Text("Close Profile", style: GoogleFonts.poppins(fontWeight: FontWeight.w600))
                 )
               ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
           Container(
             padding: EdgeInsets.all(10),
             decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
             child: Icon(icon, color: AppColors.primaryBlue, size: 20)
           ),
           SizedBox(width: 16),
           Expanded(
             child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
             ]),
           )
        ],
      )
    );
  }

  Widget _buildResourcesContent() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          "Learning Materials",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildResourceItem(
          "Ethical Code of Conduct", 
          "PDF • Google Drive", 
          Icons.gavel, 
          Colors.blue.shade700,
          url: "https://drive.google.com/file/d/1Xuu7iIUtExIQxPI_HJexbhlSWUx44l4q/view?usp=sharing"
        ),
        _buildResourceItem("Introduction to Mentoring", "PDF • 2.5 MB", Icons.picture_as_pdf, Colors.red),
        _buildResourceItem("Communication Skills", "Video • 15 min", Icons.video_library, Colors.purple),
        _buildResourceItem("Active Listening Guide", "PDF • 1.8 MB", Icons.picture_as_pdf, Colors.red),
        _buildResourceItem("Conflict Resolution", "Video • 20 min", Icons.video_library, Colors.purple),
      ],
    );
  }

  Widget _buildResourceItem(String title, String subtitle, IconData icon, Color color, {String? url}) {
    return InkWell(
      onTap: url != null ? () async {
        try {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not open resource')),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error opening resource: $e')),
            );
          }
        }
      } : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(url != null ? Icons.open_in_new : Icons.download, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildCallContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Scheduled Calls",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryBlue.withOpacity(0.1), AppColors.purpleGradientEnd.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.phone, color: AppColors.primaryBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Next Call",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            "+91 98634 61949",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      "Jan 15, 2026 • 3:00 PM",
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.call, color: Colors.white),
                        label: Text("Call Now", style: GoogleFonts.poppins(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.videocam, color: AppColors.primaryBlue),
                        label: Text("Video Call", style: GoogleFonts.poppins(color: AppColors.primaryBlue)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: AppColors.primaryBlue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSubmittingQuery = false; // Kept for safety if referenced elsewhere, though likely unused now

  // Old method placeholder to prevent build errors if referenced (though we checked)
  Widget _buildQueryContent() {
    return SizedBox.shrink(); 
  }
}

class VolunteerQuerySheet extends StatefulWidget {
  final String? menteeId;
  const VolunteerQuerySheet({Key? key, this.menteeId}) : super(key: key);

  @override
  State<VolunteerQuerySheet> createState() => _VolunteerQuerySheetState();
}

class _VolunteerQuerySheetState extends State<VolunteerQuerySheet> {
  final TextEditingController _queryController = TextEditingController();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final String baseUrl = ApiConfig.apiUrl;
  
  bool _isSubmitting = false;
  bool _isLoadingHistory = true;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final token = await secureStorage.read(key: "token");
      final response = await http.get(
        Uri.parse('$baseUrl/companion-connect/queries'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _history = data['queries'] ?? [];
            _isLoadingHistory = false;
          });
        }
      } else {
        setState(() => _isLoadingHistory = false);
      }
    } catch (e) {
      print('Error fetching history: $e');
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _submitQuery() async {
    final queryText = _queryController.text.trim();
    if (queryText.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final token = await secureStorage.read(key: "token");
      final response = await http.post(
        Uri.parse('$baseUrl/companion-connect/queries'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'query': queryText,
          'menteeId': widget.menteeId,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _queryController.clear();
        _fetchHistory(); // Refresh history
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Query submitted!"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to submit"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Support & Queries",
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: _isLoadingHistory
                ? Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                : _history.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 48, color: Colors.grey.shade300),
                            SizedBox(height: 12),
                            Text(
                              "No past queries",
                              style: GoogleFonts.poppins(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final query = _history[index];
                          final isReplied = query['status'] == 'replied';
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDate(query['createdAt']),
                                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isReplied ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isReplied ? "Replied" : "Pending",
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: isReplied ? Colors.green : Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  query['query'] ?? '',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                ),
                                if (isReplied && query['reply'] != null) ...[
                                  Divider(height: 16),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.reply, size: 14, color: AppColors.primaryBlue),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          query['reply'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
          
          const SizedBox(height: 16),
          Divider(),
          const SizedBox(height: 16),
          
          Text(
            "New Query",
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _queryController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Type your message...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitQuery,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text("Submit Query", style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return '';
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }
}

// Custom Painter for Journey Path Background
class _JourneyPathPainter extends CustomPainter {
  final int totalNodes;
  final int currentNode;
  final Color primaryColor;
  final Color completedColor;

  _JourneyPathPainter({
    required this.totalNodes,
    required this.currentNode,
    required this.primaryColor,
    required this.completedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final nodeSpacing = 115.0; // Spacing between nodes
    final startX = 60.0;
    final centerY = size.height / 2;
    final waveAmplitude = 15.0;

    // Draw wavy path connecting nodes
    for (int i = 0; i < totalNodes; i++) {
      final x = startX + (i * nodeSpacing);
      final y = centerY + (i % 2 == 0 ? -waveAmplitude : waveAmplitude);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = startX + ((i - 1) * nodeSpacing);
        final prevY = centerY + ((i - 1) % 2 == 0 ? -waveAmplitude : waveAmplitude);
        final controlX = (prevX + x) / 2;
        
        path.quadraticBezierTo(controlX, centerY, x, y);
      }
    }

    // Draw completed path (green)
    if (currentNode > 1) {
      paint.color = completedColor.withOpacity(0.3);
      paint.strokeWidth = 6;
      
      final completedPath = Path();
      for (int i = 0; i < currentNode; i++) {
        final x = startX + (i * nodeSpacing);
        final y = centerY + (i % 2 == 0 ? -waveAmplitude : waveAmplitude);
        
        if (i == 0) {
          completedPath.moveTo(x, y);
        } else {
          final prevX = startX + ((i - 1) * nodeSpacing);
          final prevY = centerY + ((i - 1) % 2 == 0 ? -waveAmplitude : waveAmplitude);
          final controlX = (prevX + x) / 2;
          
          completedPath.quadraticBezierTo(controlX, centerY, x, y);
        }
      }
      canvas.drawPath(completedPath, paint);
    }

    // Draw upcoming path (lighter)
    paint.color = Colors.grey.withOpacity(0.15);
    paint.strokeWidth = 4;
    canvas.drawPath(path, paint);

    // Draw decorative dots along the path
    final dotPaint = Paint()
      ..style = PaintingStyle.fill;
      
    for (int i = 0; i < totalNodes - 1; i++) {
      final x = startX + (i * nodeSpacing) + (nodeSpacing / 2);
      final y = centerY;
      
      dotPaint.color = i < currentNode - 1
          ? completedColor.withOpacity(0.4)
          : Colors.grey.withOpacity(0.2);
      
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_JourneyPathPainter oldDelegate) {
    return oldDelegate.currentNode != currentNode ||
        oldDelegate.totalNodes != totalNodes;
  }
}
