import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'companionconnect.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final String baseUrl = "https://shrew-concrete-cobra.ngrok-free.app/api";

  Map<String, dynamic> userData = {};
  List<Map<String, dynamic>> _availablePrograms = [];
  bool _loadingPrograms = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchPrograms();
  }

  Future<void> _fetchPrograms() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/programs'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['programs'] != null) {
          setState(() {
            _availablePrograms = List<Map<String, dynamic>>.from(
              (data['programs'] as List).map((p) => {
                'id': p['id'],
                'name': p['name'],
                'description': p['description'] ?? '',
                'order': p['order'] ?? 0,
              })
            );
            _availablePrograms.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
            _loadingPrograms = false;
          });
        }
      } else {
        setState(() => _loadingPrograms = false);
      }
    } catch (e) {
      print('Error fetching programs: $e');
      setState(() => _loadingPrograms = false);
    }
  }

  Future<void> _loadUser() async {
    // Read from secure storage
    final data = await secureStorage.read(key: "userData");
    if (data != null) {
      final decoded = json.decode(data);
      setState(() {
        // Extract user data from the backend response format
        userData = decoded["user"] ?? {};
      });
    }
  }

  Future<void> _logout() async {
    await secureStorage.deleteAll();
    Navigator.pushReplacementNamed(context, "/login");
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, "/profile");
  }

  Widget _buildWelcomeMessage() {
    final String name = userData["fullName"] ?? "Volunteer";
    final String approvalStatus = userData["approvalStatus"] ?? "";

    if (approvalStatus != "approved") {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          border: Border.all(color: Colors.orange[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              "Hello $name!",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.orange[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Thanks for applying to be a volunteer. Your application has not been approved yet. We will let you know by mail once our team reviews your application.",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.orange[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // For approved volunteers
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.verified, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back, $name!",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "You're approved and ready to volunteer ✨",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (userData["volunteerCode"] != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.badge, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "ID: ${userData["volunteerCode"]}",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // Programs Grid
        _buildProgramsGrid(),
      ],
    );
  }

  Widget _buildProgramsGrid() {
    // Get program IDs from userData
    final List<dynamic> programIds = userData["interestedPrograms"] is List
        ? userData["interestedPrograms"]
        : (userData["interestedPrograms"] is String
            ? (json.decode(userData["interestedPrograms"]) as List)
            : []);
    
    if (programIds.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_loadingPrograms) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: Color(0xFF6366F1)),
              const SizedBox(height: 12),
              Text(
                "Loading programs...",
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    // Map program IDs to program objects
    final userPrograms = _availablePrograms
        .where((p) => programIds.contains(p['id']))
        .toList();

    if (userPrograms.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign, color: Color(0xFF6366F1), size: 20),
              const SizedBox(width: 8),
              Text(
                "Your Programs",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: userPrograms.length,
            itemBuilder: (context, index) {
              final program = userPrograms[index];
              final programId = program['id'] as String;
              final programName = program['name'] as String;
              final programDescription = program['description'] as String;
              
              return GestureDetector(
                onTap: () {
                  // Navigate to program-specific page
                  if (programName == "Companion Connect") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CompanionConnectPage(programId: programId),
                      ),
                    );
                  }
                },
                child: Tooltip(
                  message: programDescription.isNotEmpty ? programDescription : programName,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getProgramColor(index).withOpacity(0.1),
                          _getProgramColor(index).withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getProgramColor(index).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getProgramColor(index).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getProgramIcon(programName),
                            color: _getProgramColor(index),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            programName,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _getProgramColor(index),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _getProgramColor(int index) {
    final colors = [
      Color(0xFF6366F1), // Indigo
      Color(0xFF8B5CF6), // Purple
      Color(0xFFEC4899), // Pink
      Color(0xFF10B981), // Green
      Color(0xFFF59E0B), // Amber
      Color(0xFF3B82F6), // Blue
    ];
    return colors[index % colors.length];
  }

  IconData _getProgramIcon(String program) {
    // Match exact program names from registration form
    switch (program) {
      case "Companion Connect":
        return Icons.people;
      case "NLSP Nawa lousing Life Skills Program":
        return Icons.school;
      case "Disaster Response Team":
        return Icons.emergency;
      case "Admin/HR":
        return Icons.admin_panel_settings;
      default:
        return Icons.campaign;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFEFFAF6),
      appBar: AppBar(
        backgroundColor: Colors.teal[700],
        title: Text("TSF Volunteer Portal", style: GoogleFonts.poppins()),
        actions: [
          // Profile section in top right
          GestureDetector(
            onTap: _navigateToProfile,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: userData["photoUrl"] != null 
                        ? NetworkImage(userData["photoUrl"]) 
                        : null,
                    backgroundColor: Colors.grey[300],
                    child: userData["photoUrl"] == null 
                        ? Icon(Icons.person, color: Colors.grey[600], size: 20)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  if (!isMobile) 
                    Text(
                      userData["fullName"] ?? "Profile",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Logout",
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Welcome message based on approval status
            _buildWelcomeMessage(),
          ],
        ),
      ),
    );
  }
}