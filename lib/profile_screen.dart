import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  Map<String, dynamic> userData = {};
  String? jwtToken;

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
  final expertiseController = TextEditingController();
  final socialMediaController = TextEditingController();
  final whyVolunteerController = TextEditingController();
  final skillsDescController = TextEditingController();
  final interestedProgramController = TextEditingController();
  final priorVolunteeringDescController = TextEditingController();
  final referenceNameController = TextEditingController();
  final referencePhoneController = TextEditingController();
  final referenceRelationController = TextEditingController();
  final referenceAffiliationController = TextEditingController();
  final specialRequirementsController = TextEditingController();
  final trustworthyMeaningController = TextEditingController();
  final conflictSituationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await secureStorage.read(key: "userData");
    if (data != null) {
      final decoded = json.decode(data);
      jwtToken = decoded["token"];
      userData = decoded["user"] ?? {};
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
      expertiseController.text = userData["expertise"] ?? "";
      socialMediaController.text = userData["socialMedia"] ?? "";
      whyVolunteerController.text = userData["whyVolunteer"] ?? "";
      skillsDescController.text = userData["skillsDesc"] ?? "";
      interestedProgramController.text = userData["interestedProgram"] ?? "";
      priorVolunteeringDescController.text = userData["priorVolunteeringDesc"] ?? "";
      referenceNameController.text = userData["referenceName"] ?? "";
      referencePhoneController.text = userData["referencePhone"] ?? "";
      referenceRelationController.text = userData["referenceRelation"] ?? "";
      referenceAffiliationController.text = userData["referenceAffiliation"] ?? "";
      specialRequirementsController.text = userData["specialRequirements"] ?? "";
      trustworthyMeaningController.text = userData["trustworthyMeaning"] ?? "";
      conflictSituationController.text = userData["conflictSituation"] ?? "";
      setState(() {});
    }
  }

  Future<void> _saveProfile() async {
    final url = Uri.parse("http://localhost:8000/api/auth/update-profile");
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
        "expertise": expertiseController.text,
        "socialMedia": socialMediaController.text,
        "whyVolunteer": whyVolunteerController.text,
        "skillsDesc": skillsDescController.text,
        "interestedProgram": interestedProgramController.text,
        "priorVolunteeringDesc": priorVolunteeringDescController.text,
        "referenceName": referenceNameController.text,
        "referencePhone": referencePhoneController.text,
        "referenceRelation": referenceRelationController.text,
        "referenceAffiliation": referenceAffiliationController.text,
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: ${response.body}")),
      );
    }
  }

  Future<void> _logout() async {
    await secureStorage.deleteAll();
    Navigator.pushReplacementNamed(context, "/login");
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFD12027),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFFD12027), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFD12027),
        title: Text("Profile", style: GoogleFonts.poppins()),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(24),
                width: isMobile ? double.infinity : 500,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (userData["photoUrl"] != null)
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(userData["photoUrl"]),
                          backgroundColor: Colors.grey[200],
                        ),
                      ),
                    const SizedBox(height: 16),
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
                    _buildTextField(expertiseController, "Expertise"),
                    _buildTextField(socialMediaController, "Social Media"),
                    _sectionHeader("Volunteering Information"),
                    _buildTextField(whyVolunteerController, "Why Volunteer"),
                    _buildTextField(skillsDescController, "Skills Description"),
                    _buildTextField(interestedProgramController, "Interested Program"),
                    _buildTextField(priorVolunteeringDescController, "Prior Volunteering Description"),
                    _buildTextField(specialRequirementsController, "Special Requirements"),
                    _sectionHeader("Reference Information"),
                    _buildTextField(referenceNameController, "Reference Name"),
                    _buildTextField(referencePhoneController, "Reference Phone"),
                    _buildTextField(referenceRelationController, "Reference Relation"),
                    _buildTextField(referenceAffiliationController, "Reference Affiliation"),
                    _sectionHeader("Other Information"),
                    _buildTextField(trustworthyMeaningController, "Trustworthy Meaning"),
                    _buildTextField(conflictSituationController, "Conflict Situation"),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _saveProfile,
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: const Text("Save"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD12027),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text("Logout"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD12027),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
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