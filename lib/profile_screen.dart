import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'config/api_config.dart';
import 'config/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  Map<String, dynamic> userData = {};
  String? jwtToken;

  // Programs
  List<Map<String, dynamic>> _availablePrograms = [];
  bool _loadingPrograms = true;
  List<String> _selectedProgramIds = []; // Track selected program IDs

  // Controllers for editable fields
  final fullNameController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final dobController = TextEditingController();
  final genderController = TextEditingController();
  final bloodGroupController = TextEditingController();
  final currentLocationController = TextEditingController();
  final highestQualificationController = TextEditingController();
  final currentOccupationController = TextEditingController();
  final organizationNameController = TextEditingController();
  // final expertiseController = TextEditingController();
  final socialMediaController = TextEditingController();
  final whyVolunteerController = TextEditingController();
  final skillsDescController = TextEditingController();
  // Remove: final interestedProgramController = TextEditingController();
  final priorVolunteeringDescController = TextEditingController();
  final referenceNameController = TextEditingController();
  final referencePhoneController = TextEditingController();
  final referenceRelationController = TextEditingController();
  final specialRequirementsController = TextEditingController();
  final trustworthyMeaningController = TextEditingController();
  final conflictSituationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _fetchPrograms();
    await _loadUser();
  }

  Future<void> _fetchPrograms() async {
    setState(() {
      _loadingPrograms = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiUrl}/programs'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['programs'] != null) {
          setState(() {
            _availablePrograms = List<Map<String, dynamic>>.from(data['programs']);
            _loadingPrograms = false;
          });
          print('Programs loaded: ${_availablePrograms.length}');
        } else {
          setState(() {
            _loadingPrograms = false;
          });
          print('Programs API failed: success=${data['success']}, programs=${data['programs']}');
        }
      } else {
        setState(() {
          _loadingPrograms = false;
        });
        print('Failed to load programs: ${response.statusCode}, body: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _loadingPrograms = false;
      });
      print('Error fetching programs: $e');
    }
  }

  Future<void> _loadUser() async {
    final data = await secureStorage.read(key: "userData");
    if (data != null) {
      final decoded = json.decode(data);
      jwtToken = decoded["token"];
      userData = decoded["user"] ?? {};
      
      // Set selected program IDs from userData
      final interestedPrograms = userData["interestedPrograms"];
      if (interestedPrograms is List) {
        _selectedProgramIds = List<String>.from(interestedPrograms);
      } else if (interestedPrograms is String) {
        try {
          _selectedProgramIds = List<String>.from(json.decode(interestedPrograms));
        } catch (e) {
          _selectedProgramIds = [];
        }
      } else {
        _selectedProgramIds = [];
      }
      
      // Populate controllers
      fullNameController.text = userData["fullName"] ?? "";
      addressController.text = userData["address"] ?? "";
      phoneController.text = userData["phone"] ?? "";
      dobController.text = userData["dob"]?.substring(0, 10) ?? "";
      genderController.text = userData["gender"] ?? "";
      bloodGroupController.text = userData["bloodGroup"] ?? "";
      currentLocationController.text = userData["currentLocation"] ?? "";
      highestQualificationController.text = userData["highestQualification"] ?? "";
      currentOccupationController.text = userData["currentOccupation"] ?? "";
      organizationNameController.text = userData["organizationName"] ?? "";
      // expertiseController.text = userData["expertise"] ?? "";
      socialMediaController.text = userData["socialMedia"] ?? "";
      whyVolunteerController.text = userData["whyVolunteer"] ?? "";
      skillsDescController.text = userData["skillsDesc"] ?? "";
      // Remove: interestedProgramController.text = _getProgramNames(userData["interestedPrograms"]) ?? userData["interestedProgram"] ?? "";
      priorVolunteeringDescController.text = userData["priorVolunteeringDesc"] ?? "";
      referenceNameController.text = userData["referenceName"] ?? "";
      referencePhoneController.text = userData["referencePhone"] ?? "";
      referenceRelationController.text = userData["referenceRelation"] ?? "";
      specialRequirementsController.text = userData["specialRequirements"] ?? "";
      trustworthyMeaningController.text = userData["trustworthyMeaning"] ?? "";
      conflictSituationController.text = userData["conflictSituation"] ?? "";
      setState(() {});
    }
  }

  Future<bool> _saveProfile() async {
    final url = Uri.parse("${ApiConfig.apiUrl}/auth/update-profile");
    final response = await http.patch(
      url,
      headers: {
        "Authorization": "Bearer $jwtToken",
        "Content-Type": "application/json",
      },
      body: json.encode({
        "fullName": fullNameController.text,
        "address": addressController.text,
        "phone": phoneController.text,
        "dob": dobController.text,
        "gender": genderController.text,
        "bloodGroup": bloodGroupController.text,
        "currentLocation": currentLocationController.text,
        "highestQualification": highestQualificationController.text,
        "currentOccupation": currentOccupationController.text,
        "organizationName": organizationNameController.text,
        // "expertise": expertiseController.text,
        "socialMedia": socialMediaController.text,
        "whyVolunteer": whyVolunteerController.text,
        "skillsDesc": skillsDescController.text,
        "interestedPrograms": _selectedProgramIds, // Use selected program IDs directly
        "priorVolunteeringDesc": priorVolunteeringDescController.text,
        "referenceName": referenceNameController.text,
        "referencePhone": referencePhoneController.text,
        "referenceRelation": referenceRelationController.text,
        "specialRequirements": specialRequirementsController.text,
        "trustworthyMeaning": trustworthyMeaningController.text,
        "conflictSituation": conflictSituationController.text,
      }),
    );
    if (response.statusCode == 200) {
      final updated = json.decode(response.body);
      userData = updated["user"] ?? userData;
      await secureStorage.write(
        key: "userData",
        value: json.encode({
          "token": jwtToken,
          "user": userData,
        }),
      );
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
      return true; // Return success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: ${response.body}")),
      );
      return false; // Return failure
    }
  }

  Future<void> _logout() async {
    await secureStorage.deleteAll();
    Navigator.pushReplacementNamed(context, "/login");
  }

  Widget _sectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 12),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withOpacity(0.1),
            AppColors.secondaryBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.star, color: Colors.white, size: 16),
          ),
          SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: AppColors.primaryBlue,
            fontSize: 14,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: AppColors.primaryBlue, width: 2.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: GoogleFonts.poppins(fontSize: 14),
      ),
    );
  }

  Widget _buildProgramsSelection() {
    if (_loadingPrograms) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(color: AppColors.primaryBlue),
                const SizedBox(height: 8),
                Text(
                  "Loading programs...",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Interested Programs",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            if (_availablePrograms.isEmpty)
              Text(
                "No programs available",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              )
            else
              ..._availablePrograms.map((program) {
                final programId = program['_id'] ?? program['id'];
                final programName = program['name'] ?? 'Unknown Program';
                final programDescription = program['description'] ?? '';

                return CheckboxListTile(
                  title: Text(
                    programName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: programDescription.isNotEmpty
                      ? Text(
                          programDescription,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        )
                      : null,
                  value: _selectedProgramIds.contains(programId),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        if (!_selectedProgramIds.contains(programId)) {
                          _selectedProgramIds.add(programId);
                        }
                      } else {
                        _selectedProgramIds.remove(programId);
                      }
                    });
                  },
                  activeColor: AppColors.primaryBlue,
                  checkColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                );
              }).toList(),
          ],
        ),
      ),
    );
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
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.person, color: Colors.white, size: 24),
            ),
            SizedBox(width: 12),
            Text(
              "My Profile",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Avatar
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.getPrimaryGradientColors(),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundImage: userData["photoUrl"] != null
                          ? NetworkImage(userData["photoUrl"])
                          : null,
                      backgroundColor: Colors.white,
                      child: userData["photoUrl"] == null
                          ? Icon(Icons.person, color: AppColors.primaryBlue, size: 50)
                          : null,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    userData["fullName"] ?? "Volunteer",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (userData["volunteerCode"] != null) ...[
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.badge, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            "ID: ${userData["volunteerCode"]}",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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
            SizedBox(height: 16),
            // Form Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                constraints: BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader("Personal Information"),
                    _buildTextField(fullNameController, "Full Name"),
                    _buildTextField(addressController, "Address"),
                    _buildTextField(phoneController, "Phone"),
                    _buildTextField(dobController, "DOB (YYYY-MM-DD)"),
                    _buildTextField(genderController, "Gender"),
                    _buildTextField(bloodGroupController, "Blood Group"),
                    _buildTextField(currentLocationController, "Current Location"),
                    _sectionHeader("Professional Information"),
                    _buildTextField(highestQualificationController, "Highest Qualification"),
                    _buildTextField(currentOccupationController, "Current Occupation"),
                    _buildTextField(organizationNameController, "Organization Name"),
                    // _buildTextField(expertiseController, "Expertise"),
                    _buildTextField(socialMediaController, "Social Media"),
                    _sectionHeader("Volunteering Information"),
                    _buildTextField(whyVolunteerController, "Why Volunteer"),
                    _buildTextField(skillsDescController, "Skills Description"),
                    // Replace text field with program checkboxes
                    _buildProgramsSelection(),
                    _buildTextField(priorVolunteeringDescController, "Prior Volunteering Description"),
                    _buildTextField(specialRequirementsController, "Special Requirements"),
                    _sectionHeader("Reference Information"),
                    _buildTextField(referenceNameController, "Reference Name"),
                    _buildTextField(referencePhoneController, "Reference Phone"),
                    _buildTextField(referenceRelationController, "Reference Relation"),
                    _sectionHeader("Other Information"),
                    _buildTextField(trustworthyMeaningController, "Trustworthy Meaning"),
                    _buildTextField(conflictSituationController, "Conflict Situation"),
                    const SizedBox(height: 24),
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.accentGreen, Colors.green.shade600],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentGreen.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final success = await _saveProfile();
                                if (success) {
                                  // Return true to indicate profile was updated
                                  Navigator.of(context).pop(true);
                                }
                              },
                              icon: const Icon(Icons.save, color: Colors.white, size: 20),
                              label: Text(
                                "Save Changes",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.accentOrange, Colors.deepOrange],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentOrange.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                              label: Text(
                                "Logout",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}