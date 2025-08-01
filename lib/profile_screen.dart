import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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

  Widget _buildInfoTile(String title, String? value) {
    return value != null && value.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$title: ", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                Expanded(child: Text(value, style: GoogleFonts.poppins())),
              ],
            ),
          )
        : const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFEFFAF6),
      appBar: AppBar(
        backgroundColor: Colors.teal[700],
        title: Text("Profile", style: GoogleFonts.poppins()),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(24),
                width: isMobile ? double.infinity : 500,
                child: Column(
                  children: [
                    if (userData["photoUrl"] != null)
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(userData["photoUrl"]),
                        backgroundColor: Colors.grey[200],
                      ),
                    const SizedBox(height: 16),
                    _buildInfoTile("Full Name", userData["fullName"]),
                    _buildInfoTile("Email", userData["email"]),
                    _buildInfoTile("Role", userData["role"]),
                    _buildInfoTile("Expertise", userData["expertise"]),
                    _buildInfoTile("DOB", userData["dob"]?.substring(0, 10)),
                    _buildInfoTile("Address", userData["address"]),
                    _buildInfoTile("Why Volunteer", userData["whyVolunteer"]),
                    _buildInfoTile("Verified", userData["verified"]?.toString()),
                    _buildInfoTile("Approval Status", userData["approvalStatus"]),
                    _buildInfoTile("Approved By", userData["approvedBy"]),
                    _buildInfoTile("Approved At", userData["approvedAt"]?.substring(0, 10)),
                    _buildInfoTile("Created At", userData["createdAt"]?.substring(0, 10)),
                    _buildInfoTile("Updated At", userData["updatedAt"]?.substring(0, 10)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: Text("Logout", style: GoogleFonts.poppins()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}