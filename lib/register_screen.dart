import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Section 1: Personal Details
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String? _gender;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _currentLocationController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _socialMediaController = TextEditingController();
  XFile? _photoFile;
  XFile? _aadharFile;

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

  Future<void> _pickFile(bool isPhoto) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isPhoto) {
          _photoFile = picked;
        } else {
          _aadharFile = picked;
        }
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all required fields", style: GoogleFonts.poppins())),
      );
      return;
    }
    if (_photoFile == null || _aadharFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please upload photo and aadhar", style: GoogleFonts.poppins())),
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

    // Add files
    request.files.add(await http.MultipartFile.fromPath('photo', _photoFile!.path));
    request.files.add(await http.MultipartFile.fromPath('aadhar', _aadharFile!.path));

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

  List<Step> get _steps => [
    // SECTION 1: Personal Details
    Step(
      title: const Text("Personal"),
      isActive: _currentStep >= 0,
      content: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: "Email"),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          ),
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo),
                  label: Text(_photoFile == null ? "Upload Photo" : "Change Photo"),
                  onPressed: () => _pickFile(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(_aadharFile == null ? "Upload Aadhar" : "Change Aadhar"),
                  onPressed: () => _pickFile(false),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    // SECTION 2: Education & Work
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
    // ...Repeat for all other sections...
    // Final Step: Submit
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
      body: Stepper(
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
    );
  }
}