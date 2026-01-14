import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CompanionConnectPage extends StatefulWidget {
  final String programId;
  
  const CompanionConnectPage({super.key, required this.programId});

  @override
  State<CompanionConnectPage> createState() => _CompanionConnectPageState();
}

class _CompanionConnectPageState extends State<CompanionConnectPage> {
  final String baseUrl = "https://shrew-concrete-cobra.ngrok-free.app/api";
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
  final TextEditingController _assistanceController = TextEditingController();
  final TextEditingController _otherTopicController = TextEditingController();
  final TextEditingController _redFlagsController = TextEditingController();
  
  double _moodScore = 3.0;
  String _mentorHelpfulness = "Yes"; 
  
  final List<Map<String, dynamic>> _checklistItems = [
    {'label': 'Health & Hygiene', 'isAchieved': false},
    {'label': 'Emotional Well-being', 'isAchieved': false},
    {'label': 'Academic Progress', 'isAchieved': false},
    {'label': 'Future Goals', 'isAchieved': false},
  ];
  
  final List<String> _availableTopics = ['Studies', 'Health', 'Family', 'Hobbies', 'Skills', 'Others'];
  final List<String> _selectedTopics = [];

  @override
  void initState() {
    super.initState();
    _fetchMentee();
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
      
      final bodyPayload = {
          'menteeId': menteeId,
          'note': _postCallNoteController.text.trim(),
          'cellNumber': currentCell,
          'callDuration': int.tryParse(_callDurationController.text) ?? 0,
          'followUpRequired': _assistanceController.text.trim().isNotEmpty,
          'assistanceRequest': _assistanceController.text.trim(),
          'moodScore': _moodScore,
          'checklist': _checklistItems,
          'topics': _selectedTopics,
          'otherTopicDetail': _selectedTopics.contains('Others') ? _otherTopicController.text.trim() : '',
          'mentorHelpfulness': _mentorHelpfulness,
          'redFlags': _redFlagsController.text.trim(),
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
              content: Text("Note saved successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          _postCallNoteController.clear();
          _callDurationController.clear();
          _assistanceController.clear();
          _otherTopicController.clear();
          _redFlagsController.clear();
          setState(() {
             _moodScore = 3.0;
             _mentorHelpfulness = "Yes";
             _selectedTopics.clear();
             for (var item in _checklistItems) item['isAchieved'] = false;
          });
          // Refresh notes
          _fetchCallNotes();
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

  Future<void> _advanceProgress() async {
    if (_menteeData == null) return;
    
    final currentCell = _menteeData!['currentCell'] ?? 1;
    // Removed cap of 3. Allow unlimited calls.

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
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
            
            // Log Post Call Note
            _buildPostCallNoteSection(),
            
            // Call History
            // Call History moved to bottom sheet
            
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildMenteeInfoCard() {
    if (_loadingMentee) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
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
    final String phone = _menteeData!['phone'] ?? 'N/A';
    final String location = _menteeData!['location'] ?? 'N/A';
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
                backgroundColor: Color(0xFF6366F1).withOpacity(0.1),
                child: photoUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          photoUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                             return Icon(Icons.person, color: Color(0xFF6366F1), size: 30);
                          },
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
          _buildInfoRow(Icons.phone, "Phone", phone),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.calendar_today, "Assigned", assignedDate),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on_outlined, "Location", location),
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1).withOpacity(0.1), Color(0xFF8B5CF6).withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF6366F1).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.timeline, color: Color(0xFF6366F1), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Call Journey",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        "Current: Call #$currentCell",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _advanceProgress,
                icon: Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                label: Text("Complete", style: GoogleFonts.poppins(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6366F1),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: null, // Indeterminate to show ongoing journey
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(Color(0xFF6366F1)),
              minHeight: 6,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Mark 'Complete' after finishing call #$currentCell to move to #$currentCell + 1.",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
          ),
        ],
      ),
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
                ? LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  )
                : null,
            color: isActive ? null : Colors.grey.shade300,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Color(0xFF6366F1).withOpacity(0.3),
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
            color: isActive ? Color(0xFF6366F1) : Colors.grey.shade600,
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
              Icon(Icons.edit_note, color: Color(0xFF6366F1)),
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
                child: Slider(
                  value: _moodScore,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: "$_moodScore",
                  activeColor: Color(0xFF6366F1),
                  onChanged: (v) => setState(() => _moodScore = v),
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
          Text("Discussion Goals (Achieved?)", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
          ..._checklistItems.map((item) {
             return CheckboxListTile(
                title: Text(item['label'], style: GoogleFonts.poppins(fontSize: 13)),
                value: item['isAchieved'],
                activeColor: Color(0xFF6366F1),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) => setState(() => item['isAchieved'] = v),
             );
          }).toList(),
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
                selectedColor: Color(0xFF6366F1).withOpacity(0.2),
                checkmarkColor: Color(0xFF6366F1),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isSelected ? Color(0xFF6366F1) : Colors.black87,
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
              hintText: "Write your observations, discussions, and details...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),

          // 5. Assistance
          Text("Assistance Needed / Follow-up", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _assistanceController,
            maxLines: 2,
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              hintText: "Any support needed from admin?",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),
          
          // 6. Mentor Helpfulness
          Text("Did you find this call helpful?", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
          Row(
            children: ["Yes", "Neutral", "No"].map((opt) => 
               Expanded(
                 child: RadioListTile<String>(
                   title: Text(opt, style: GoogleFonts.poppins(fontSize: 13)),
                   value: opt,
                   groupValue: _mentorHelpfulness,
                   activeColor: Color(0xFF6366F1),
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
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              hintText: "Report any concerning behavior...",
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

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Color(0xFF6366F1).withOpacity(0.3), blurRadius: 8, offset: Offset(0, 2))],
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
        child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
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
                color: Color(0xFF1E293B),
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
                          color: Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Call #$callNum",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6366F1),
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
                  Text("View Details", style: GoogleFonts.poppins(fontSize: 12, color: Color(0xFF6366F1), fontWeight: FontWeight.w500)),
                  Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF6366F1)),
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
                        backgroundColor: Color(0xFF6366F1).withOpacity(0.1),
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

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.video_library, "Resources"),
              _buildNavItem(1, Icons.call, "Call"),
              _buildNavItem(3, Icons.history, "History"),
              _buildNavItem(2, Icons.help_outline, "Query"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
        _showBottomSheet(index);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
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
      return Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
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
                   backgroundColor: Color(0xFF6366F1).withOpacity(0.1),
                   child: _menteeData!['photoUrl'] != null && _menteeData!['photoUrl'].toString().isNotEmpty 
                      ? ClipOval(
                          child: Image.network(
                            _menteeData!['photoUrl'],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                               return Icon(Icons.person, size: 50, color: Color(0xFF6366F1));
                            },
                          ),
                        ) 
                      : Icon(Icons.person, size: 50, color: Color(0xFF6366F1)),
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
               _buildProfileDetailRow(Icons.location_on, "Location", "${_menteeData!['location'] ?? 'N/A'}"),
               _buildProfileDetailRow(Icons.school, "Program", "${_menteeData!['program']?['name'] ?? 'N/A'}"),
               _buildProfileDetailRow(Icons.calendar_today, "Assigned On", "${_menteeData!['assignedAt']?.substring(0,10) ?? 'N/A'}"),
               if (_menteeData!['phone'] != null)
                 _buildProfileDetailRow(Icons.phone, "Phone", "${_menteeData!['phone']}"),
                 
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
             decoration: BoxDecoration(color: Color(0xFF6366F1).withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
             child: Icon(icon, color: Color(0xFF6366F1), size: 20)
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
        _buildResourceItem("Introduction to Mentoring", "PDF • 2.5 MB", Icons.picture_as_pdf, Colors.red),
        _buildResourceItem("Communication Skills", "Video • 15 min", Icons.video_library, Colors.purple),
        _buildResourceItem("Active Listening Guide", "PDF • 1.8 MB", Icons.picture_as_pdf, Colors.red),
        _buildResourceItem("Conflict Resolution", "Video • 20 min", Icons.video_library, Colors.purple),
      ],
    );
  }

  Widget _buildResourceItem(String title, String subtitle, IconData icon, Color color) {
    return Container(
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
          Icon(Icons.download, color: color),
        ],
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
                colors: [Color(0xFF6366F1).withOpacity(0.1), Color(0xFF8B5CF6).withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF6366F1).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.phone, color: Color(0xFF6366F1)),
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
                        icon: Icon(Icons.videocam, color: Color(0xFF6366F1)),
                        label: Text("Video Call", style: GoogleFonts.poppins(color: Color(0xFF6366F1))),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Color(0xFF6366F1)),
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
  final String baseUrl = "https://shrew-concrete-cobra.ngrok-free.app/api";
  
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
                ? Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
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
                                      Icon(Icons.reply, size: 14, color: Color(0xFF6366F1)),
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
                backgroundColor: Color(0xFF6366F1),
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
