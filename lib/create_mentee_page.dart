import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'config/api_config.dart';
import 'config/app_colors.dart';

class CreateMenteePage extends StatefulWidget {
  final String companionConnectProgramId;
  
  const CreateMenteePage({super.key, required this.companionConnectProgramId});

  @override
  State<CreateMenteePage> createState() => _CreateMenteePageState();
}

class _CreateMenteePageState extends State<CreateMenteePage> {
  final String baseUrl = ApiConfig.apiUrl;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  
  bool _isSubmitting = false;
  
  // Form fields
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _pointOfContactController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  DateTime? _selectedDate;
  String? _gender;
  Uint8List? _photoBytes; // Changed from File to Uint8List for web support
  String? _photoFileName;
  
  final List<String> _genderOptions = ["Male", "Female", "Other"];

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _regionController.dispose();
    _gradeController.dispose();
    _pointOfContactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Important for web - loads file as bytes
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _photoBytes = result.files.single.bytes;
          _photoFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking photo: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2010, 1, 1),
      firstDate: DateTime(2000),
      lastDate: DateTime(2020),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select date of birth'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select gender'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await secureStorage.read(key: "adminToken"); // Changed from "token" to "adminToken"
      
      // For now, we'll send without photo upload (you can add Cloudinary upload if needed)
      final response = await http.post(
        Uri.parse('$baseUrl/companion-connect/admin/mentees'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'fullName': _fullNameController.text.trim(),
          'dob': _selectedDate!.toIso8601String(),
          'gender': _gender,
          'phone': _phoneController.text.trim(),
          'region': _regionController.text.trim(),
          'grade': _gradeController.text.trim(),
          'pointOfContact': _pointOfContactController.text.trim(),
          'programId': widget.companionConnectProgramId,
          'notes': _notesController.text.trim(),
        }),
      );

      setState(() => _isSubmitting = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mentee created successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Return true to refresh list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to create mentee'), backgroundColor: Colors.red),
          );
        }
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Error creating mentee'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
            gradient: AppColors.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
        title: Text("Create New Mentee", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo picker
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryBlue, width: 2),
                  ),
                  child: _photoBytes != null
                      ? ClipOval(
                          child: Image.memory(
                            _photoBytes!,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 40, color: AppColors.primaryBlue),
                            const SizedBox(height: 8),
                            Text(
                              'Add Photo',
                              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primaryBlue),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Full Name
            TextFormField(
              controller: _fullNameController,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: Icon(Icons.person, color: AppColors.primaryBlue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Full name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date of Birth
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'Date of Birth *'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: GoogleFonts.poppins(
                          color: _selectedDate == null ? Colors.grey.shade600 : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Gender
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: InputDecoration(
                labelText: 'Gender *',
                prefixIcon: Icon(Icons.wc, color: AppColors.primaryBlue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                ),
              ),
              items: _genderOptions.map((gender) {
                return DropdownMenuItem(value: gender, child: Text(gender));
              }).toList(),
              onChanged: (value) {
                setState(() => _gender = value);
              },
              validator: (value) {
                if (value == null) {
                  return 'Gender is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              style: GoogleFonts.poppins(),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                prefixIcon: Icon(Icons.phone, color: AppColors.primaryBlue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Region
            TextFormField(
              controller: _regionController,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                labelText: 'Region *',
                prefixIcon: Icon(Icons.location_on, color: AppColors.primaryBlue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Region is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Grade
            TextFormField(
              controller: _gradeController,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                labelText: 'Grade *',
                prefixIcon: Icon(Icons.school, color: AppColors.primaryBlue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                ),
                hintText: 'e.g., Class 10, Grade 8',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Grade is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Point of Contact
            TextFormField(
              controller: _pointOfContactController,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                labelText: 'Point of Contact *',
                prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryBlue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                ),
                hintText: 'Primary contact person name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Point of contact is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              style: GoogleFonts.poppins(),
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                prefixIcon: Icon(Icons.notes, color: AppColors.primaryBlue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                ),
                hintText: 'Any additional information about the mentee...',
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Create Mentee',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
