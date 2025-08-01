import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  Map<String, dynamic> userData = {};

  @override
  void initState() {
    super.initState();
    _loadUser();
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
    } else {
      // Fallback sample data for development if no secure storage data
      final sampleBackendResponse = {
        "success": true,
        "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY4ODlkNmYyNjY2ZTVlM2Y1MDAxNWM2NyIsImlhdCI6MTc1MzkzNjMxNCwiZXhwIjoxNzU0NTQxMTE0fQ.0nryWaFRoX0Skby2UE7sjhfXFhlBuCv80BkLwWAheUw",
        "user": {
          "_id": "6889d6f2666e5e3f50015c67",
          "email": "satyammay123@gmail.com",
          "verified": true,
          "role": "volunteer",
          "approvalStatus": "approved",
          "approvedBy": "admin@tsf.com",
          "otp": null,
          "otpExpires": null,
          "createdAt": "2025-07-30T08:25:22.127Z",
          "updatedAt": "2025-07-31T04:31:54.619Z",
          "__v": 0,
          "address": "Sega Road",
          "dob": "2004-12-31T18:30:00.000Z",
          "expertise": "Teaching",
          "fullName": "Satyam",
          "photoUrl": "https://res.cloudinary.com/dfxofpwum/image/upload/v1753864030/tsf_profiles/wzzug7lqsnztf8jaun6s.jpg",
          "whyVolunteer": "Want to",
          "approvedAt": "2025-07-30T08:28:53.798Z"
        }
      };
      
      setState(() {
        userData = Map<String, dynamic>.from(sampleBackendResponse["user"] as Map);
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

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "Welcome back, $name! You're approved and ready to volunteer.",
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.green[800],
        ),
        textAlign: TextAlign.center,
      ),
    );
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