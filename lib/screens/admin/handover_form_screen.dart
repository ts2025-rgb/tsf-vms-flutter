import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/volunteer_model.dart';
import '../../services/vms_service.dart';

/// Handover Form Screen for completing handover during exit process
class HandoverFormScreen extends StatefulWidget {
  final String volunteerId;
  final Volunteer? volunteer;

  const HandoverFormScreen({
    super.key,
    required this.volunteerId,
    this.volunteer,
  });

  @override
  State<HandoverFormScreen> createState() => _HandoverFormScreenState();
}

class _HandoverFormScreenState extends State<HandoverFormScreen> {
  final VMSService _vmsService = VMSService();
  final _formKey = GlobalKey<FormState>();
  
  final _childNameController = TextEditingController();
  final _childStatusController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoading = false;
  Volunteer? _volunteer;

  // Theme colors
  static const primaryColor = Color(0xFF1E88E5);
  static const backgroundColor = Color(0xFFF8FFFE);
  static const textPrimary = Color(0xFF2C3E50);
  static const textSecondary = Color(0xFF7F8C8D);

  @override
  void initState() {
    super.initState();
    _volunteer = widget.volunteer;
    if (_volunteer == null) {
      _loadVolunteer();
    }
  }

  @override
  void dispose() {
    _childNameController.dispose();
    _childStatusController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadVolunteer() async {
    setState(() => _isLoading = true);
    
    final response = await _vmsService.getVolunteerDetails(widget.volunteerId);
    
    setState(() {
      if (response.isSuccess) {
        _volunteer = response.data;
      }
      _isLoading = false;
    });
  }

  Future<void> _submitHandover() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final response = await _vmsService.completeHandover(
      widget.volunteerId,
      childName: _childNameController.text.trim(),
      childStatus: _childStatusController.text.trim().isNotEmpty 
          ? _childStatusController.text.trim() 
          : null,
      notes: _notesController.text.trim().isNotEmpty 
          ? _notesController.text.trim() 
          : null,
    );
    
    setState(() => _isLoading = false);
    
    if (response.isSuccess) {
      _showSuccess('Handover completed successfully');
      Navigator.pop(context, true);
    } else {
      _showError(response.error ?? 'Failed to complete handover');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(
          'Complete Handover',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading && _volunteer == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Volunteer Info Card
                    if (_volunteer != null) _buildVolunteerInfoCard(),
                    const SizedBox(height: 24),
                    
                    // Form Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Please provide details about the child being handed over from this volunteer\'s mentoring.',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Child Name Field (Required)
                    Text(
                      'Child Name *',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _childNameController,
                      decoration: InputDecoration(
                        hintText: 'Enter the child\'s name',
                        prefixIcon: const Icon(Icons.child_care_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Child name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Child Current Status Field (Optional)
                    Text(
                      'Child\'s Current Status',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _childStatusController,
                      decoration: InputDecoration(
                        hintText: 'e.g., Progressing well, Needs additional support',
                        prefixIcon: const Icon(Icons.assessment_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    
                    // Handover Notes Field (Optional)
                    Text(
                      'Handover Notes',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        hintText: 'Any additional notes about the handover...',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 60),
                          child: Icon(Icons.notes_rounded),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitHandover,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF26A69A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFF26A69A).withOpacity(0.4),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.assignment_turned_in_rounded, size: 22),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Complete Handover',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildVolunteerInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: _volunteer!.photoUrl != null
                ? NetworkImage(_volunteer!.photoUrl!)
                : null,
            backgroundColor: primaryColor.withOpacity(0.1),
            child: _volunteer!.photoUrl == null
                ? Icon(Icons.person_rounded, size: 28, color: primaryColor)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_volunteer!.volunteerCode != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _volunteer!.volunteerCode!,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _volunteer!.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                Text(
                  _volunteer!.email ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Exit Pending',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
