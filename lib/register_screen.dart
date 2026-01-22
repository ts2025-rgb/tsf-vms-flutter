import 'dart:convert';
// import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'config/api_config.dart';
import 'config/app_colors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}


class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // OTP step state
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _emailVerified = false;
  bool _otpSent = false;
  bool _sendingOtp = false;
  bool _verifyingOtp = false;

  // Section 1: Personal Details
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String? _gender;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _currentLocationController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _socialMediaController = TextEditingController();
  PlatformFile? _photoFile;
  PlatformFile? _aadharFile;

  // Section 2: Education & Work
  final TextEditingController _highestQualificationController = TextEditingController();
  final TextEditingController _currentOccupationController = TextEditingController();
  bool _corporateExperience = false;
  final TextEditingController _organizationNameController = TextEditingController();

  // Section 3: Volunteering Intent & Preferences
  bool _priorVolunteering = false;
  final TextEditingController _priorVolunteeringDescController = TextEditingController();
  List<String> _interestedProgramIds = []; // Changed to store IDs instead of names
  final TextEditingController _whyVolunteerController = TextEditingController();
  String? _hoursPerWeek;

  // Section 4: Skills & Role Preferences
  List<String> _skills = [];
  List<String> _customSkills = []; // Custom skills added by user
  final TextEditingController _customSkillController = TextEditingController();
  final TextEditingController _skillsDescController = TextEditingController();
  List<String> _preferredRoles = [];
  List<String> _customRoles = []; // Custom roles added by user
  final TextEditingController _customRoleController = TextEditingController();
  final TextEditingController _specialRequirementsController = TextEditingController();
  String? _meiteilon;

  // Section 5: Character Reference & Documents
  final TextEditingController _referenceNameController = TextEditingController();
  final TextEditingController _referenceRelationController = TextEditingController();
  final TextEditingController _referencePhoneController = TextEditingController();
  final TextEditingController _referenceAffiliationController = TextEditingController();

  // Section 6: Situational & Personal Reflection
  final TextEditingController _trustworthyMeaningController = TextEditingController();
  final TextEditingController _conflictSituationController = TextEditingController();


  // Section 7: Declarations & Policies
  bool _childProtectionAccepted = false;
  bool _poshPolicyAccepted = false;

  // Submit loading state
  bool _isSubmitting = false;

  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final String baseUrl = ApiConfig.apiUrl;

  // Multi-select options
  final List<String> _skillsOptions = [
    "Survey Taking", "Psychosocial Counseling", "Coordinating Volunteers", "Volunteer Recruitment",
    "Logistics", "Documentation", "Facilitating Activities", "Drawing and Art", "Teaching",
    "First Aid and Medical Assistance", "Event Planning", "Social Media & Communication",
    "Photography / Videography", "Data Entry", "Mentoring and Tutoring", "Microsoft Office Suite",
    "Content Writing", "Web Development", "Helpline Management", "Reel Making", "Fundraising"
  ];
  final List<String> _rolesOptions = [
    "Event Management & Logistics", "Teaching", "Activity Organising", "Virtual Mentorship",
    "Documentation", "Parent Counseling & Community Relations", "Content & Social Media",
    "Donation & Recycling", "Volunteer Mobilization", "Rapid Relief"
  ];
  
  // Programs - loaded dynamically from API
  List<Map<String, dynamic>> _availablePrograms = [];
  bool _loadingPrograms = true;
  final List<String> _genderOptions = ["Male", "Female", "Other"];
  final List<String> _locationOptions = [
    "Imphal, Manipur", "Other Valley Districts", "Hill Districts", "Outside Manipur (including Abroad)"
  ];
  final List<String> _bloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"];
  final List<String> _hoursOptions = ["Less than 4 hours", "4-8 hours", "8-16 hours", "16+ hours"];
  final List<String> _meiteilonOptions = ["Yes", "No", "I can understand but not speak fluently"];

  // File validation helpers
  static const int maxFileSize = 1024 * 1024; // 1MB
  static const List<String> allowedImageTypes = ["jpg", "jpeg", "png"];
  static const List<String> allowedAadharTypes = ["jpg", "jpeg", "png", "pdf"];

  String? _fileError;

  @override
  void initState() {
    super.initState();
    _fetchPrograms();
  }

  Future<void> _fetchPrograms() async {
    setState(() {
      _loadingPrograms = true;
    });

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
            // Sort by order
            _availablePrograms.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
            _loadingPrograms = false;
          });
        }
      } else {
        setState(() {
          _loadingPrograms = false;
        });
        print('Failed to load programs: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _loadingPrograms = false;
      });
      print('Error fetching programs: $e');
    }
  }

  Future<void> _pickFile(String type) async {
    FileType fileType = FileType.custom;
    List<String> allowedExtensions = [];
    if (type == 'photo') {
      allowedExtensions = allowedImageTypes;
    } else {
      allowedExtensions = allowedAadharTypes;
    }
    final result = await FilePicker.platform.pickFiles(
      type: fileType,
      allowedExtensions: allowedExtensions,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final fileSize = file.size;
      final ext = file.extension?.toLowerCase() ?? '';
      bool valid = false;
      if (type == 'photo') {
        valid = allowedImageTypes.contains(ext);
      } else {
        valid = allowedAadharTypes.contains(ext);
      }
      if (!valid) {
        setState(() {
          _fileError = "Invalid file type. Allowed: ${type.contains('Aadhar') ? allowedAadharTypes.join(', ') : allowedImageTypes.join(', ')}";
        });
        return;
      }
      if (fileSize > maxFileSize) {
        setState(() {
          _fileError = "File too large. Max 1MB allowed.";
        });
        return;
      }
      setState(() {
        _fileError = null;
        if (type == 'photo') _photoFile = file;
        if (type == 'aadhar') _aadharFile = file;
      });
    }
  }


  void _toggleMultiSelect(List<String> list, String value) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
    });
  }

  Future<void> _showChildProtectionDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Child Protection Policy",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "As a volunteer working with conflict-affected children in Manipur, India, I acknowledge the importance of ensuring the safety, dignity, and well-being of every child under my care. I commit to upholding the highest standards of conduct and agree to the following:",
                  style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 16),
                _buildPolicyPoint(
                  "1.",
                  "I will treat all children with respect and dignity, ensuring their voices are heard and their rights are protected.",
                ),
                _buildPolicyPoint(
                  "2.",
                  "I will prioritise the physical and emotional safety of all children, avoiding any behaviour or action that could harm them, and will report any concerns about their welfare immediately to the appropriate authorities.",
                ),
                _buildPolicyPoint(
                  "3.",
                  "I will maintain the confidentiality of all personal information related to the children, sharing it only with those directly responsible for their care and protection.",
                ),
                _buildPolicyPoint(
                  "4.",
                  "I will respect and be sensitive to the cultural, religious, and social norms of the children and their communities.",
                ),
                _buildPolicyPoint(
                  "5.",
                  "I will not discriminate against any child based on gender, ethnicity, religion, or background, ensuring that all children are treated equally.",
                ),
                _buildPolicyPoint(
                  "6.",
                  "I will maintain professional boundaries at all times and avoid any form of physical, emotional, or verbal abuse.",
                ),
                _buildPolicyPoint(
                  "7.",
                  "I commit to upholding a strict zero-tolerance policy towards any form of sexual abuse or misconduct involving children. I will immediately report any suspected or confirmed incidents of sexual abuse to the appropriate authorities, without delay.",
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    "By accepting this undertaking, I commit to adhering to these principles and understand that any breach of this policy may result in the termination of my volunteer engagement and action of authorities if found with any misconduct towards children under the laws of India. Further any consequences of such misconduct or crime is solely my responsibility.",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("Decline", style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              child: Text("I Accept", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );

    if (result == true) {
      setState(() {
        _childProtectionAccepted = true;
      });
    }
  }

  Widget _buildPolicyPoint(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              number,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPOSHDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.security_outlined, color: Colors.purple.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "POSH Declaration",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "I hereby declare that I understand and respect the principles of Prevention of Sexual Harassment (POSH) as outlined by the Tengbang Sintha Foundation.",
                  style: GoogleFonts.poppins(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Text(
                  "I commit to maintaining a safe, inclusive, and respectful environment for all individuals involved in the program, whether in-person or online.",
                  style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 16),
                Text(
                  "I pledge to:",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPOSHPoint("•", "Uphold dignity and respect in all interactions."),
                _buildPOSHPoint(
                  "•",
                  "Refrain from any form of harassment, discrimination, or inappropriate behavior.",
                ),
                _buildPOSHPoint(
                  "•",
                  "Report any incidents or concerns to the designated POSH Committee promptly and responsibly.",
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Text(
                    "By agreeing to this declaration, I acknowledge my commitment to fostering a harassment-free and respectful environment for all.",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.purple.shade900,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("Decline", style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
              ),
              child: Text("I Accept", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );

    if (result == true) {
      setState(() {
        _poshPolicyAccepted = true;
      });
    }
  }

  Widget _buildPOSHPoint(String bullet, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Text(
              bullet,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.purple.shade700,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _sendOtp() async {
    setState(() { _sendingOtp = true; });
    try {
      final res = await http.post(Uri.parse("$baseUrl/auth/send-register-otp"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"email": _emailController.text.trim()}),
      );
      final decoded = json.decode(res.body);
      if (res.statusCode == 200 && decoded["success"] == true) {
        setState(() { _otpSent = true; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OTP sent to your email", style: GoogleFonts.poppins())),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decoded["message"] ?? "Failed to send OTP", style: GoogleFonts.poppins())),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send OTP", style: GoogleFonts.poppins())),
      );
    } finally {
      setState(() { _sendingOtp = false; });
    }
  }

  Future<void> _verifyOtp() async {
    setState(() { _verifyingOtp = true; });
    try {
      final res = await http.post(Uri.parse("$baseUrl/auth/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": _emailController.text.trim(),
          "otp": _otpController.text.trim(),
        }),
      );
      final decoded = json.decode(res.body);
      if (res.statusCode == 200 && decoded["success"] == true) {
        setState(() { _emailVerified = true; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Email verified. Please complete registration.", style: GoogleFonts.poppins())),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decoded["message"] ?? "Invalid OTP", style: GoogleFonts.poppins())),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to verify OTP", style: GoogleFonts.poppins())),
      );
    } finally {
      setState(() { _verifyingOtp = false; });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all required fields", style: GoogleFonts.poppins())),
      );
      return;
    }
    if (_photoFile == null || _aadharFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please upload all required files", style: GoogleFonts.poppins())),
      );
      return;
    }
    if (_fileError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_fileError!, style: GoogleFonts.poppins())),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    print('=== REGISTRATION VALIDATION DEBUG ===');
    print('Form validation passed: ${_formKey.currentState!.validate()}');
    print('Files check:');
    print('  _photoFile: ${_photoFile?.name ?? 'null'}');
    print('  _aadharFile: ${_aadharFile?.name ?? 'null'}');
    print('  _fileError: $_fileError');
    print('=====================================');

    final uri = Uri.parse('$baseUrl/auth/register');
    final request = http.MultipartRequest("POST", uri);

    // Add all fields
    request.fields['email'] = _emailController.text.trim();
    request.fields['fullName'] = _fullNameController.text.trim();
    request.fields['dob'] = _dobController.text.trim();
    request.fields['gender'] = _gender ?? "";
    request.fields['phone'] = _phoneController.text.trim();
    request.fields['address'] = _addressController.text.trim();
    request.fields['expertise'] = _skills.join(", ");
    request.fields['currentLocation'] = _currentLocationController.text.trim();
    request.fields['bloodGroup'] = _bloodGroupController.text.trim();
    request.fields['socialMedia'] = _socialMediaController.text.trim();
    request.fields['highestQualification'] = _highestQualificationController.text.trim();
    request.fields['currentOccupation'] = _currentOccupationController.text.trim();
    request.fields['corporateExperience'] = _corporateExperience.toString();
    request.fields['organizationName'] = _organizationNameController.text.trim();
    request.fields['priorVolunteering'] = _priorVolunteering.toString();
    request.fields['priorVolunteeringDesc'] = _priorVolunteeringDescController.text.trim();
    request.fields['interestedPrograms'] = json.encode(_interestedProgramIds);
    request.fields['whyVolunteer'] = _whyVolunteerController.text.trim();
    request.fields['hoursPerWeek'] = _hoursPerWeek ?? "";
    // Combine predefined and custom skills
    final allSkills = [..._skills, ..._customSkills];
    request.fields['skills'] = json.encode(allSkills);
    request.fields['skillsDesc'] = _skillsDescController.text.trim();
    // Combine predefined and custom roles
    final allRoles = [..._preferredRoles, ..._customRoles];
    request.fields['preferredRoles'] = json.encode(allRoles);
    request.fields['specialRequirements'] = _specialRequirementsController.text.trim();
    request.fields['meiteilon'] = _meiteilon ?? "";
    request.fields['referenceName'] = _referenceNameController.text.trim();
    request.fields['referenceRelation'] = _referenceRelationController.text.trim();
    request.fields['referencePhone'] = _referencePhoneController.text.trim();
    request.fields['referenceAffiliation'] = _referenceAffiliationController.text.trim();
    request.fields['trustworthyMeaning'] = _trustworthyMeaningController.text.trim();
    request.fields['conflictSituation'] = _conflictSituationController.text.trim();

    request.fields['childProtectionUndertaking'] = _childProtectionAccepted.toString();
    request.fields['poshPolicyAccepted'] = _poshPolicyAccepted.toString();

    // Helper to add files for web and non-web
    Future<void> addFile(String field, PlatformFile? file) async {
      if (file == null) return;
      if (kIsWeb || file.bytes != null) {
        // On web or if bytes are available, use fromBytes
        request.files.add(
          http.MultipartFile.fromBytes(field, file.bytes!, filename: file.name),
        );
      } else if (file.path != null) {
        // On mobile/desktop, use fromPath
        request.files.add(
          await http.MultipartFile.fromPath(field, file.path!),
        );
      }
    }

    await addFile('photo', _photoFile);
    await addFile('aadhar', _aadharFile);

    try {
      print('=== REGISTRATION REQUEST DEBUG ===');
      print('Sending registration request to: ${uri.toString()}');
      print('Request fields:');
      request.fields.forEach((key, value) {
        print('  $key: $value');
      });
      print('Request files:');
      for (var file in request.files) {
        print('  ${file.field}: ${file.filename} (${file.length} bytes)');
      }
      print('=====================================');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print('=== REGISTRATION RESPONSE DEBUG ===');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: $responseBody');
      print('====================================');

      final decoded = json.decode(responseBody);

      if (response.statusCode == 200 && decoded["success"] == true) {
        print('Registration successful!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Registration successful! Redirecting to login...", style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
        // Wait a moment to show the success message, then navigate to login
        await Future.delayed(const Duration(milliseconds: 1500));
        Navigator.pushReplacementNamed(context, "/login");
      } else {
        print('Registration failed - Status: ${response.statusCode}, Success: ${decoded["success"]}');
        print('Error message: ${decoded["message"]}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decoded["message"] ?? "Registration failed", style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('=== REGISTRATION ERROR DEBUG ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('=================================');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to register. Please try again.", style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Only show steps if email is verified
  List<Step> get _steps => [
    // 1. Personal Details
    Step(
      title: Text("Personal Details", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      isActive: _currentStep >= 0,
      content: Column(
        children: [
          TextFormField(
            controller: _fullNameController,
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              labelText: "Full Name",
              prefixIcon: const Icon(Icons.person_outline, color: Colors.teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dobController,
            readOnly: true,
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              labelText: "Date of Birth",
              prefixIcon: const Icon(Icons.calendar_today_outlined, color: Colors.teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
                initialDate: DateTime(2000),
              );
              if (picked != null) {
                _dobController.text = "${picked.toLocal()}".split(' ')[0];
              }
            },
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _gender,
            items: _genderOptions.map((g) => DropdownMenuItem(
              value: g, 
              child: Text(g, style: GoogleFonts.poppins())
            )).toList(),
            onChanged: (v) => setState(() => _gender = v),
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              labelText: "Gender",
              prefixIcon: const Icon(Icons.wc_outlined, color: Colors.teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (v) => v == null ? "Required" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            style: GoogleFonts.poppins(),
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: "Phone Number",
              prefixIcon: const Icon(Icons.phone_outlined, color: Colors.teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            style: GoogleFonts.poppins(),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: "Address",
              prefixIcon: const Icon(Icons.home_outlined, color: Colors.teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _currentLocationController.text.isEmpty ? null : _currentLocationController.text,
            items: _locationOptions.map((l) => DropdownMenuItem(
              value: l, 
              child: Text(l, style: GoogleFonts.poppins())
            )).toList(),
            onChanged: (v) => setState(() => _currentLocationController.text = v ?? ""),
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              labelText: "Current Location",
              prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (v) => v == null ? "Required" : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _bloodGroupController.text.isEmpty ? null : _bloodGroupController.text,
            items: _bloodGroups.map((b) => DropdownMenuItem(
              value: b, 
              child: Text(b, style: GoogleFonts.poppins())
            )).toList(),
            onChanged: (v) => setState(() => _bloodGroupController.text = v ?? ""),
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              labelText: "Blood Group",
              prefixIcon: const Icon(Icons.bloodtype_outlined, color: Colors.teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (v) => v == null ? "Required" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _socialMediaController,
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              labelText: "Social Media Profile Link(s)",
              prefixIcon: const Icon(Icons.link_outlined, color: Colors.teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              helperText: "Instagram, Facebook, LinkedIn, or other social media profile",
            ),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_upload_outlined, color: Colors.orange.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Document Upload", 
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, 
                          color: Colors.orange.shade700
                        )
                      ),
                      Text("Upload your photo and Aadhar (Max 1MB each)", 
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.photo_camera_outlined, 
                      color: _photoFile != null ? Colors.green : Colors.teal),
                    label: Text(
                      _photoFile == null ? "Your Photo" : "Photo Selected",
                      style: GoogleFonts.poppins(
                        color: _photoFile != null ? Colors.green : Colors.teal
                      )
                    ),
                    onPressed: () => _pickFile('photo'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.credit_card_outlined,
                      color: _aadharFile != null ? Colors.green : Colors.teal),
                    label: Text(
                      _aadharFile == null ? "Your Aadhar" : "Aadhar Selected",
                      style: GoogleFonts.poppins(
                        color: _aadharFile != null ? Colors.green : Colors.teal
                      )
                    ),
                    onPressed: () => _pickFile('aadhar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_fileError != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_fileError!, 
                        style: GoogleFonts.poppins(
                          color: Colors.red.shade700,
                          fontSize: 12
                        )
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
    // 2. Education & Work
    Step(
      title: Text("Education & Work", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      isActive: _currentStep >= 1,
      content: Column(
        children: [
          TextFormField(
            controller: _highestQualificationController,
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              labelText: "Highest Qualification",
              prefixIcon: const Icon(Icons.school_outlined, color: Colors.teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _currentOccupationController,
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              labelText: "Current Occupation",
              prefixIcon: const Icon(Icons.work_outline, color: Colors.teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: Text("Do you have corporate experience?", style: GoogleFonts.poppins()),
              subtitle: Text("Toggle if you have worked in corporate environment", 
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              value: _corporateExperience,
              onChanged: (v) => setState(() => _corporateExperience = v),
              activeColor: Colors.teal,
            ),
          ),
          if (_corporateExperience) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _organizationNameController,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                labelText: "Organization Name",
                prefixIcon: const Icon(Icons.business_outlined, color: Colors.teal),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ],
        ],
      ),
    ),
    // 3. Volunteering Intent & Preferences
    Step(
      title: Text("Volunteering", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      isActive: _currentStep >= 2,
      content: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: Text("Have you volunteered before?", style: GoogleFonts.poppins()),
              subtitle: Text("Toggle if you have prior volunteering experience", 
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              value: _priorVolunteering,
              onChanged: (v) => setState(() => _priorVolunteering = v),
              activeColor: Colors.teal,
            ),
          ),
          if (_priorVolunteering) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _priorVolunteeringDescController,
              style: GoogleFonts.poppins(),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Describe Your Prior Volunteering Experience",
                prefixIcon: const Icon(Icons.volunteer_activism_outlined, color: Colors.teal),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.campaign_outlined, color: Colors.indigo.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Interested Programs",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Select all programs you're interested in",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _loadingPrograms
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: Colors.indigo.shade700),
                        const SizedBox(height: 12),
                        Text(
                          "Loading programs...",
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              : _availablePrograms.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_outlined, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Unable to load programs. Please check your connection and try again.",
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange.shade700),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availablePrograms.map((program) {
                        final programId = program['id'] as String;
                        final programName = program['name'] as String;
                        final description = program['description'] as String;
                        final isSelected = _interestedProgramIds.contains(programId);
                        
                        return Tooltip(
                          message: description.isNotEmpty ? description : programName,
                          child: FilterChip(
                            label: Text(programName, style: GoogleFonts.poppins(fontSize: 12)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _interestedProgramIds.add(programId);
                                } else {
                                  _interestedProgramIds.remove(programId);
                                }
                              });
                            },
                            backgroundColor: Colors.grey.shade100,
                            selectedColor: Colors.indigo.shade100,
                            checkmarkColor: Colors.indigo.shade700,
                            side: BorderSide(
                              color: isSelected ? Colors.indigo : Colors.grey.shade300,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _whyVolunteerController,
            style: GoogleFonts.poppins(),
            maxLines: 4,
            decoration: InputDecoration(
              labelText: "Why do you want to volunteer with us?",
              prefixIcon: const Icon(Icons.favorite_outline, color: Colors.teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              helperText: "Tell us your motivation and goals",
            ),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _hoursPerWeek,
            items: _hoursOptions.map((h) => DropdownMenuItem(
              value: h, 
              child: Text(h, style: GoogleFonts.poppins())
            )).toList(),
            onChanged: (v) => setState(() => _hoursPerWeek = v),
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              labelText: "Hours per week you can contribute",
              prefixIcon: const Icon(Icons.access_time_outlined, color: Colors.teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (v) => v == null ? "Required" : null,
          ),
        ],
      ),
    ),
    // 4. Skills & Role Preferences
    Step(
      title: Text("Skills & Roles", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      isActive: _currentStep >= 3,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star_outline, color: Colors.teal.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text("Select Your Skills", 
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, 
                        color: Colors.teal.shade700
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text("Choose multiple skills that match your expertise", 
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skillsOptions.map((skill) => FilterChip(
              label: Text(skill, style: GoogleFonts.poppins(fontSize: 12)),
              selected: _skills.contains(skill),
              onSelected: (selected) => _toggleMultiSelect(_skills, skill),
              backgroundColor: Colors.grey.shade100,
              selectedColor: Colors.teal.shade100,
              checkmarkColor: Colors.teal.shade700,
              side: BorderSide(
                color: _skills.contains(skill) ? Colors.teal : Colors.grey.shade300
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),
          // Custom Skills Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text("Add Custom Skills", 
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, 
                        color: Colors.orange.shade700
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text("Type a skill and press comma (,) or Enter to add", 
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customSkillController,
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              labelText: "Type your skill here",
              hintText: "e.g., Video Editing, Graphic Design, Public Speaking",
              prefixIcon: const Icon(Icons.edit_outlined, color: Colors.orange),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              // Check if comma is pressed
              if (value.endsWith(',')) {
                final skill = value.substring(0, value.length - 1).trim();
                if (skill.isNotEmpty && !_customSkills.contains(skill)) {
                  setState(() {
                    _customSkills.add(skill);
                    _customSkillController.clear();
                  });
                }
              }
            },
            onSubmitted: (value) {
              final skill = value.trim();
              if (skill.isNotEmpty && !_customSkills.contains(skill)) {
                setState(() {
                  _customSkills.add(skill);
                  _customSkillController.clear();
                });
              }
            },
          ),
          if (_customSkills.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _customSkills.map((skill) => Chip(
                label: Text(skill, style: GoogleFonts.poppins(fontSize: 12)),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _customSkills.remove(skill);
                  });
                },
                backgroundColor: Colors.orange.shade100,
                deleteIconColor: Colors.orange.shade700,
                side: BorderSide(color: Colors.orange.shade300),
              )).toList(),
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _skillsDescController,
            style: GoogleFonts.poppins(),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: "Describe your skills in detail",
              prefixIcon: const Icon(Icons.lightbulb_outline, color: Colors.teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              helperText: "Elaborate on your selected skills and experience",
            ),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.assignment_outlined, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text("Preferred Roles", 
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, 
                        color: Colors.green.shade700
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text("Select roles you'd like to take on", 
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _rolesOptions.map((role) => FilterChip(
              label: Text(role, style: GoogleFonts.poppins(fontSize: 12)),
              selected: _preferredRoles.contains(role),
              onSelected: (selected) => _toggleMultiSelect(_preferredRoles, role),
              backgroundColor: Colors.grey.shade100,
              selectedColor: Colors.green.shade100,
              checkmarkColor: Colors.green.shade700,
              side: BorderSide(
                color: _preferredRoles.contains(role) ? Colors.green : Colors.grey.shade300
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),
          // Custom Roles Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.purple.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text("Add Custom Roles", 
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, 
                        color: Colors.purple.shade700
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text("Type a role and press comma (,) or Enter to add", 
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customRoleController,
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              labelText: "Type your preferred role here",
              hintText: "e.g., Project Manager, Team Leader, Content Creator",
              prefixIcon: const Icon(Icons.work_outline, color: Colors.purple),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              // Check if comma is pressed
              if (value.endsWith(',')) {
                final role = value.substring(0, value.length - 1).trim();
                if (role.isNotEmpty && !_customRoles.contains(role)) {
                  setState(() {
                    _customRoles.add(role);
                    _customRoleController.clear();
                  });
                }
              }
            },
            onSubmitted: (value) {
              final role = value.trim();
              if (role.isNotEmpty && !_customRoles.contains(role)) {
                setState(() {
                  _customRoles.add(role);
                  _customRoleController.clear();
                });
              }
            },
          ),
          if (_customRoles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _customRoles.map((role) => Chip(
                label: Text(role, style: GoogleFonts.poppins(fontSize: 12)),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _customRoles.remove(role);
                  });
                },
                backgroundColor: Colors.purple.shade100,
                deleteIconColor: Colors.purple.shade700,
                side: BorderSide(color: Colors.purple.shade300),
              )).toList(),
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _specialRequirementsController,
            style: GoogleFonts.poppins(),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: "Special Requirements (if any)",
              prefixIcon: const Icon(Icons.accessible_outlined, color: Colors.teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              helperText: "Any accessibility needs or special accommodations",
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _meiteilon,
            items: _meiteilonOptions.map((m) => DropdownMenuItem(
              value: m, 
              child: Text(m, style: GoogleFonts.poppins())
            )).toList(),
            onChanged: (v) => setState(() => _meiteilon = v),
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              labelText: "Can you speak Meiteilon?",
              prefixIcon: const Icon(Icons.language_outlined, color: Colors.teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (v) => v == null ? "Required" : null,
          ),
        ],
      ),
    ),
    // 5. Character Reference & Documents
    Step(
      title: Text("Reference & Documents", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      isActive: _currentStep >= 4,
      content: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.person_pin_outlined, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Character Reference", 
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, 
                          color: Colors.blue.shade700
                        )
                      ),
                      Text("Provide details of someone who can vouch for your character", 
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _referenceNameController,
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              labelText: "Reference Full Name",
              prefixIcon: const Icon(Icons.person_outline, color: Colors.teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _referenceRelationController,
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              labelText: "Relationship with Reference",
              prefixIcon: const Icon(Icons.family_restroom_outlined, color: Colors.teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              helperText: "e.g., Teacher, Supervisor, Family Friend",
            ),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _referencePhoneController,
            style: GoogleFonts.poppins(),
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: "Reference Phone Number",
              prefixIcon: const Icon(Icons.phone_outlined, color: Colors.teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _referenceAffiliationController,
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              labelText: "Reference Affiliation/Organization",
              prefixIcon: const Icon(Icons.business_outlined, color: Colors.teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),

        ],
      ),
    ),
    // 6. Situational & Personal Reflection
    Step(
      title: Text("Reflection", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      isActive: _currentStep >= 5,
      content: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.psychology_outlined, color: Colors.purple.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Personal Reflection", 
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, 
                          color: Colors.purple.shade700
                        )
                      ),
                      Text("Help us understand your values and approach to challenges", 
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _trustworthyMeaningController,
            style: GoogleFonts.poppins(),
            maxLines: 4,
            decoration: InputDecoration(
              labelText: "What does 'trustworthy' mean to you?",
              prefixIcon: const Icon(Icons.verified_outlined, color: Colors.teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              helperText: "Share your personal definition and examples",
            ),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _conflictSituationController,
            style: GoogleFonts.poppins(),
            maxLines: 4,
            decoration: InputDecoration(
              labelText: "Describe a conflict situation and how you handled it",
              prefixIcon: const Icon(Icons.mediation_outlined, color: Colors.teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              helperText: "Tell us about your problem-solving approach",
            ),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),

        ],
      ),
    ),
    // 7. Declarations & Policies
    Step(
      title: Text("Declarations", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      isActive: _currentStep >= 6,
      content: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.policy_outlined, color: Colors.red.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Policies & Declarations", 
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, 
                          color: Colors.red.shade700
                        )
                      ),
                      Text("Important commitments for volunteer safety and conduct", 
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _childProtectionAccepted ? Colors.green.shade300 : Colors.grey.shade300,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: _childProtectionAccepted ? Colors.green.shade50 : null,
            ),
            child: CheckboxListTile(
              title: Text(
                "I accept the Child Protection Policy Undertaking",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    "Click to read the full policy and accept",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (_childProtectionAccepted) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "Accepted",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              value: _childProtectionAccepted,
              onChanged: (bool? value) {
                if (value == true) {
                  _showChildProtectionDialog();
                } else {
                  setState(() {
                    _childProtectionAccepted = false;
                  });
                }
              },
              activeColor: Colors.red.shade700,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
          if (!_childProtectionAccepted)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_outlined, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Child Protection Policy acceptance is required to proceed",
                        style: GoogleFonts.poppins(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _poshPolicyAccepted ? Colors.green.shade300 : Colors.grey.shade300,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: _poshPolicyAccepted ? Colors.green.shade50 : null,
            ),
            child: CheckboxListTile(
              title: Text(
                "I accept the POSH Policy",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    "Prevention of Sexual Harassment - Click to read and accept",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (_poshPolicyAccepted) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "Accepted",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              value: _poshPolicyAccepted,
              onChanged: (bool? value) {
                if (value == true) {
                  _showPOSHDialog();
                } else {
                  setState(() {
                    _poshPolicyAccepted = false;
                  });
                }
              },
              activeColor: Colors.purple.shade700,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
          if (!_poshPolicyAccepted)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_outlined, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "POSH Policy acceptance is required to proceed",
                        style: GoogleFonts.poppins(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
    // 8. Submit
    Step(
      title: Text("Submit", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      isActive: _currentStep >= 7,
      content: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade50, Colors.green.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle_outline, size: 48, color: Colors.teal.shade700),
                const SizedBox(height: 16),
                Text(
                  "Ready to Submit",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Thank you for completing all sections. Click below to submit your volunteer registration.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitForm,
                    icon: _isSubmitting 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send_outlined, color: Colors.white),
                    label: Text(
                      _isSubmitting ? "Submitting Registration..." : "Submit Registration",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSubmitting ? Colors.grey.shade400 : Colors.teal.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "After submission, our team will review your application and contact you within 3-5 business days.",
                    style: GoogleFonts.poppins(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _emailVerified ? AppBar(
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
              child: Icon(Icons.app_registration, size: 24),
            ),
            const SizedBox(width: 12),
            Text("Volunteer Registration", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ],
        ),
      ) : null,
      body: _emailVerified
          ? Column(
              children: [
                // Progress Indicator
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Step ${_currentStep + 1} of ${_steps.length}",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          Text(
                            "${((_currentStep + 1) / _steps.length * 100).toInt()}% Complete",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (_currentStep + 1) / _steps.length,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
              children: [
                Form(
                  key: _formKey,
                  child: Stepper(
                    type: StepperType.vertical,
                    currentStep: _currentStep,
                    onStepContinue: () {
                      if (_currentStep < _steps.length - 1) {
                        setState(() => _currentStep += 1);
                      }
                    },
                    onStepCancel: () {
                      if (_currentStep > 0) {
                        setState(() => _currentStep -= 1);
                      }
                    },
                    steps: _steps,
                    controlsBuilder: (context, details) {
                      return Container(
                        margin: const EdgeInsets.only(top: 20.0),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            if (_currentStep > 0)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isSubmitting ? null : details.onStepCancel,
                                  icon: Icon(Icons.arrow_back, size: 18),
                                  label: Text("Back", style: GoogleFonts.poppins()),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            if (_currentStep > 0) const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryBlue.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _isSubmitting ? null : details.onStepContinue,
                                  icon: _isSubmitting
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Icon(
                                          _currentStep == _steps.length - 1
                                              ? Icons.check_circle
                                              : Icons.arrow_forward,
                                          size: 20,
                                        ),
                                  label: Text(
                                    _currentStep == _steps.length - 1 ? "Submit" : "Continue",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (_isSubmitting)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Submitting Registration",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Please wait while we process your application...",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
                ),
              ],
            )
          : Center(
              child: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width < 450 ? double.infinity : 400,
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/images/logo.png', height: 120),
                        const SizedBox(height: 20),
                        Text(
                          "Pathways for Purpose",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Volunteer Registration",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.teal[700],
                          ),
                        ),
                        const SizedBox(height: 28),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.poppins(),
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: const Icon(Icons.email_outlined, color: Colors.teal),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          enabled: !_otpSent,
                          validator: (v) => v == null || v.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 16),

                        if (_otpSent && !_emailVerified)
                          TextFormField(
                            controller: _otpController,
                            style: GoogleFonts.poppins(),
                            decoration: InputDecoration(
                              labelText: "Enter OTP",
                              prefixIcon: const Icon(Icons.lock_clock, color: Colors.teal),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),

                        const SizedBox(height: 16),

                        if (!_otpSent)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _sendingOtp ? null : _sendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _sendingOtp
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text("Send OTP", style: GoogleFonts.poppins(fontSize: 16)),
                            ),
                          ),

                        if (_otpSent && !_emailVerified)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _verifyingOtp ? null : _verifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[800],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _verifyingOtp
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text("Verify OTP", style: GoogleFonts.poppins(fontSize: 16)),
                            ),
                          ),

                        const SizedBox(height: 20),
                        
                        // Back to login link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Already have an account?", style: GoogleFonts.poppins(fontSize: 14)),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                "Login",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.teal[700],
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
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
    );
  }
}
