import 'dart:convert';
// import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

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
  PlatformFile? _referencePhotoFile;
  PlatformFile? _referenceAadharFile;

  // Section 2: Education & Work
  final TextEditingController _highestQualificationController = TextEditingController();
  final TextEditingController _currentOccupationController = TextEditingController();
  bool _corporateExperience = false;
  final TextEditingController _organizationNameController = TextEditingController();

  // Section 3: Volunteering Intent & Preferences
  bool _priorVolunteering = false;
  final TextEditingController _priorVolunteeringDescController = TextEditingController();
  String? _interestedProgram;
  final TextEditingController _whyVolunteerController = TextEditingController();
  String? _hoursPerWeek;

  // Section 4: Skills & Role Preferences
  List<String> _skills = [];
  final TextEditingController _skillsDescController = TextEditingController();
  List<String> _preferredRoles = [];
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
  bool _willingOrientation = false;

  // Section 7: Declarations & Policies
  final TextEditingController _childProtectionUndertakingController = TextEditingController();
  bool _poshPolicyAccepted = false;

  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final String baseUrl = "http://localhost:8000/api";

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
  final List<String> _programOptions = [
    "Companion Connect", "NLSP Nawa lousing Life Skills Program", "Disaster Response Team", "Admin/HR"
  ];
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

  Future<void> _pickFile(String type) async {
    FileType fileType = FileType.custom;
    List<String> allowedExtensions = [];
    if (type == 'photo' || type == 'referencePhoto') {
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
      if (type == 'photo' || type == 'referencePhoto') {
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
        if (type == 'referencePhoto') _referencePhotoFile = file;
        if (type == 'referenceAadhar') _referenceAadharFile = file;
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
    if (_photoFile == null || _aadharFile == null || _referencePhotoFile == null || _referenceAadharFile == null) {
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
    request.fields['interestedProgram'] = _interestedProgram ?? "";
    request.fields['whyVolunteer'] = _whyVolunteerController.text.trim();
    request.fields['hoursPerWeek'] = _hoursPerWeek ?? "";
    request.fields['skills'] = json.encode(_skills);
    request.fields['skillsDesc'] = _skillsDescController.text.trim();
    request.fields['preferredRoles'] = json.encode(_preferredRoles);
    request.fields['specialRequirements'] = _specialRequirementsController.text.trim();
    request.fields['meiteilon'] = _meiteilon ?? "";
    request.fields['referenceName'] = _referenceNameController.text.trim();
    request.fields['referenceRelation'] = _referenceRelationController.text.trim();
    request.fields['referencePhone'] = _referencePhoneController.text.trim();
    request.fields['referenceAffiliation'] = _referenceAffiliationController.text.trim();
    request.fields['trustworthyMeaning'] = _trustworthyMeaningController.text.trim();
    request.fields['conflictSituation'] = _conflictSituationController.text.trim();
    request.fields['willingOrientation'] = _willingOrientation.toString();
    request.fields['childProtectionUndertaking'] = _childProtectionUndertakingController.text.trim();
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
    await addFile('referencePhoto', _referencePhotoFile);
    await addFile('referenceAadhar', _referenceAadharFile);

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final decoded = json.decode(responseBody);

      if (response.statusCode == 200 && decoded["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration successful", style: GoogleFonts.poppins())),
        );
        Navigator.pushReplacementNamed(context, "/home");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decoded["message"] ?? "Registration failed", style: GoogleFonts.poppins())),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to register", style: GoogleFonts.poppins())),
      );
    }
  }

  // Only show steps if email is verified
  List<Step> get _steps => [
    // 1. Personal Details
    Step(
      title: const Text("Personal"),
      isActive: _currentStep >= 0,
      content: Column(
        children: [
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(labelText: "Full Name"),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          TextFormField(
            controller: _dobController,
            readOnly: true,
            decoration: const InputDecoration(labelText: "Date of Birth"),
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
          DropdownButtonFormField<String>(
            value: _gender,
            items: _genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (v) => setState(() => _gender = v),
            decoration: const InputDecoration(labelText: "Gender"),
            validator: (v) => v == null ? "Required" : null,
          ),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: "Phone"),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: "Address"),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          DropdownButtonFormField<String>(
            value: _currentLocationController.text.isEmpty ? null : _currentLocationController.text,
            items: _locationOptions.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
            onChanged: (v) => setState(() => _currentLocationController.text = v ?? ""),
            decoration: const InputDecoration(labelText: "Current Location"),
            validator: (v) => v == null ? "Required" : null,
          ),
          DropdownButtonFormField<String>(
            value: _bloodGroupController.text.isEmpty ? null : _bloodGroupController.text,
            items: _bloodGroups.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
            onChanged: (v) => setState(() => _bloodGroupController.text = v ?? ""),
            decoration: const InputDecoration(labelText: "Blood Group"),
            validator: (v) => v == null ? "Required" : null,
          ),
          TextFormField(
            controller: _socialMediaController,
            decoration: const InputDecoration(labelText: "Social Media Profile Link(s)"),
          ),
        ],
      ),
    ),
    // 2. Education & Work
    Step(
      title: const Text("Education & Work"),
      isActive: _currentStep >= 1,
      content: Column(
        children: [
          TextFormField(
            controller: _highestQualificationController,
            decoration: const InputDecoration(labelText: "Highest Qualification"),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          TextFormField(
            controller: _currentOccupationController,
            decoration: const InputDecoration(labelText: "Current Occupation"),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          SwitchListTile(
            title: const Text("Corporate Experience?"),
            value: _corporateExperience,
            onChanged: (v) => setState(() => _corporateExperience = v),
          ),
          if (_corporateExperience)
            TextFormField(
              controller: _organizationNameController,
              decoration: const InputDecoration(labelText: "Organization Name"),
            ),
        ],
      ),
    ),
    // 3. Volunteering Intent & Preferences
    Step(
      title: const Text("Volunteering"),
      isActive: _currentStep >= 2,
      content: Column(
        children: [
          SwitchListTile(
            title: const Text("Prior Volunteering?"),
            value: _priorVolunteering,
            onChanged: (v) => setState(() => _priorVolunteering = v),
          ),
          if (_priorVolunteering)
            TextFormField(
              controller: _priorVolunteeringDescController,
              decoration: const InputDecoration(labelText: "Describe Prior Volunteering"),
            ),
          DropdownButtonFormField<String>(
            value: _interestedProgram,
            items: _programOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (v) => setState(() => _interestedProgram = v),
            decoration: const InputDecoration(labelText: "Interested Program"),
            validator: (v) => v == null ? "Required" : null,
          ),
          TextFormField(
            controller: _whyVolunteerController,
            decoration: const InputDecoration(labelText: "Why do you want to volunteer?"),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          DropdownButtonFormField<String>(
            value: _hoursPerWeek,
            items: _hoursOptions.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
            onChanged: (v) => setState(() => _hoursPerWeek = v),
            decoration: const InputDecoration(labelText: "Hours per week"),
            validator: (v) => v == null ? "Required" : null,
          ),
        ],
      ),
    ),
    // 4. Skills & Role Preferences
    Step(
      title: const Text("Skills & Roles"),
      isActive: _currentStep >= 3,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Select Skills (multiple):"),
          Wrap(
            spacing: 8,
            children: _skillsOptions.map((skill) => FilterChip(
              label: Text(skill),
              selected: _skills.contains(skill),
              onSelected: (selected) => _toggleMultiSelect(_skills, skill),
            )).toList(),
          ),
          TextFormField(
            controller: _skillsDescController,
            decoration: const InputDecoration(labelText: "Describe your skills"),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 8),
          const Text("Preferred Roles (multiple):"),
          Wrap(
            spacing: 8,
            children: _rolesOptions.map((role) => FilterChip(
              label: Text(role),
              selected: _preferredRoles.contains(role),
              onSelected: (selected) => _toggleMultiSelect(_preferredRoles, role),
            )).toList(),
          ),
          TextFormField(
            controller: _specialRequirementsController,
            decoration: const InputDecoration(labelText: "Special Requirements (if any)"),
          ),
          DropdownButtonFormField<String>(
            value: _meiteilon,
            items: _meiteilonOptions.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => _meiteilon = v),
            decoration: const InputDecoration(labelText: "Can you speak Meiteilon?"),
            validator: (v) => v == null ? "Required" : null,
          ),
        ],
      ),
    ),
    // 5. Character Reference & Documents
    Step(
      title: const Text("Reference & Documents"),
      isActive: _currentStep >= 4,
      content: Column(
        children: [
          TextFormField(
            controller: _referenceNameController,
            decoration: const InputDecoration(labelText: "Reference Name"),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          TextFormField(
            controller: _referenceRelationController,
            decoration: const InputDecoration(labelText: "Reference Relation"),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          TextFormField(
            controller: _referencePhoneController,
            decoration: const InputDecoration(labelText: "Reference Phone"),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          TextFormField(
            controller: _referenceAffiliationController,
            decoration: const InputDecoration(labelText: "Reference Affiliation"),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo),
                  label: Text(_photoFile == null ? "Upload Photo" : _photoFile!.name),
                  onPressed: () => _pickFile('photo'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(_aadharFile == null ? "Upload Aadhar" : _aadharFile!.name),
                  onPressed: () => _pickFile('aadhar'),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.person),
                  label: Text(_referencePhotoFile == null ? "Reference Photo" : _referencePhotoFile!.name),
                  onPressed: () => _pickFile('referencePhoto'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(_referenceAadharFile == null ? "Reference Aadhar" : _referenceAadharFile!.name),
                  onPressed: () => _pickFile('referenceAadhar'),
                ),
              ),
            ],
          ),
          if (_fileError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(_fileError!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    ),
    // 6. Situational & Personal Reflection
    Step(
      title: const Text("Reflection"),
      isActive: _currentStep >= 5,
      content: Column(
        children: [
          TextFormField(
            controller: _trustworthyMeaningController,
            decoration: const InputDecoration(labelText: "What does trustworthy mean to you?"),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          TextFormField(
            controller: _conflictSituationController,
            decoration: const InputDecoration(labelText: "Describe a conflict situation and how you handled it"),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          SwitchListTile(
            title: const Text("Willing to attend orientation?"),
            value: _willingOrientation,
            onChanged: (v) => setState(() => _willingOrientation = v),
          ),
        ],
      ),
    ),
    // 7. Declarations & Policies
    Step(
      title: const Text("Declarations"),
      isActive: _currentStep >= 6,
      content: Column(
        children: [
          TextFormField(
            controller: _childProtectionUndertakingController,
            decoration: const InputDecoration(labelText: "Child Protection Undertaking"),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
          SwitchListTile(
            title: const Text("Accept POSH Policy?"),
            value: _poshPolicyAccepted,
            onChanged: (v) => setState(() => _poshPolicyAccepted = v),
          ),
        ],
      ),
    ),
    // 8. Submit
    Step(
      title: const Text("Submit"),
      isActive: _currentStep >= 7,
      content: Center(
        child: ElevatedButton(
          onPressed: _submitForm,
          child: const Text("Submit Registration"),
        ),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.teal[800],
        title: Text("Register", style: GoogleFonts.poppins()),
      ),
      body: _emailVerified
          ? Form(
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
                  return Row(
                    children: [
                      if (_currentStep < _steps.length - 1)
                        ElevatedButton(
                          onPressed: details.onStepContinue,
                          child: const Text("Next"),
                        ),
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text("Back"),
                        ),
                    ],
                  );
                },
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Form(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: "Email"),
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_otpSent,
                        validator: (v) => v == null || v.isEmpty ? "Required" : null,
                      ),
                        const SizedBox(height: 16),
                      if (!_otpSent)
                        ElevatedButton(
                          onPressed: _sendingOtp ? null : _sendOtp,
                          child: _sendingOtp
                              ? const CircularProgressIndicator()
                              : const Text("Send OTP"),
                        ),
                      if (_otpSent && !_emailVerified) ...[
                        TextFormField(
                          controller: _otpController,
                          decoration: const InputDecoration(labelText: "Enter OTP"),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _verifyingOtp ? null : _verifyOtp,
                          child: _verifyingOtp
                              ? const CircularProgressIndicator()
                              : const Text("Verify OTP"),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
