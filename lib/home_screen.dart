import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'companionconnect.dart';
import 'config/api_config.dart';
import 'config/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final String baseUrl = ApiConfig.apiUrl;

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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accentYellow.withOpacity(0.15),
              AppColors.accentOrange.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accentOrange.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentOrange.withOpacity(0.1),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.hourglass_empty, color: AppColors.accentOrange, size: 32),
            ),
            SizedBox(height: 16),
            Text(
              "Hello $name!",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.accentOrange,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Thanks for applying to be a volunteer. Your application is under review. We'll notify you by email once our team completes the approval process.",
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.5,
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
              colors: AppColors.getPrimaryGradientColors(),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.3),
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
              CircularProgressIndicator(color: AppColors.primaryBlue),
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
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withOpacity(0.1),
                  AppColors.secondaryBlue.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.dashboard_customize, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  "Your Programs",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                    letterSpacing: 0.3,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${userPrograms.length}",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getProgramColor(index).withOpacity(0.15),
                          _getProgramColor(index).withOpacity(0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _getProgramColor(index).withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getProgramColor(index).withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getProgramColor(index).withOpacity(0.3),
                                _getProgramColor(index).withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: _getProgramColor(index).withOpacity(0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            _getProgramIcon(programName),
                            color: _getProgramColor(index),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            programName,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _getProgramColor(index),
                              height: 1.3,
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
      AppColors.primaryBlue, // Primary Blue
      AppColors.secondaryBlue, // Secondary Blue
      AppColors.accentOrange, // Accent Orange
      AppColors.accentGreen, // Accent Green
      AppColors.accentYellow, // Accent Yellow
      AppColors.tertiaryBlue, // Tertiary Blue
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryBlue, AppColors.secondaryBlue, AppColors.tertiaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
              child: Image.asset(
                'assets/images/logo.png',
                height: 28,
                width: 28,
              ),
            ),
            SizedBox(width: 12),
            Text(
              "TSF VMS",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
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