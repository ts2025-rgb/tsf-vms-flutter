import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/volunteer_model.dart';
import '../../services/vms_service.dart';
import '../../widgets/lifecycle_progress_indicator.dart';
import '../../widgets/status_dropdowns.dart';

/// Volunteer Detail Screen with expanded view and lifecycle management
class VolunteerDetailScreen extends StatefulWidget {
  final String volunteerId;
  final Volunteer? initialVolunteer;

  const VolunteerDetailScreen({
    super.key,
    required this.volunteerId,
    this.initialVolunteer,
  });

  @override
  State<VolunteerDetailScreen> createState() => _VolunteerDetailScreenState();
}

class _VolunteerDetailScreenState extends State<VolunteerDetailScreen> {
  final VMSService _vmsService = VMSService();
  
  bool _isLoading = true;
  bool _isUpdating = false;
  Volunteer? _volunteer;
  String? _error;

  // Theme colors
  static const primaryColor = Color(0xFF1E88E5);
  static const backgroundColor = Color(0xFFF8FFFE);
  static const textPrimary = Color(0xFF2C3E50);
  static const textSecondary = Color(0xFF7F8C8D);

  @override
  void initState() {
    super.initState();
    _volunteer = widget.initialVolunteer;
    _loadVolunteerDetails();
  }

  Future<void> _loadVolunteerDetails() async {
    setState(() => _isLoading = true);

    final response = await _vmsService.getVolunteerDetails(widget.volunteerId);

    setState(() {
      if (response.isSuccess) {
        _volunteer = response.data;
        _error = null;
      } else {
        _error = response.error;
      }
      _isLoading = false;
    });
  }

  Future<void> _updateOnboardingStatus(OnboardingStatus status) async {
    if (_volunteer == null) return;
    
    setState(() => _isUpdating = true);
    
    final response = await _vmsService.updateOnboardingStatus(_volunteer!.id, status);
    
    setState(() {
      _isUpdating = false;
      if (response.isSuccess) {
        _volunteer = response.data;
        _showSuccess('Onboarding status updated');
      } else {
        _showError(response.error ?? 'Failed to update status');
      }
    });
  }

  Future<void> _updateTrainingStatus(TrainingStatus status) async {
    if (_volunteer == null) return;
    
    DateTime? scheduledDate;
    if (status == TrainingStatus.scheduled) {
      scheduledDate = await _selectDate();
      if (scheduledDate == null) return;
    }
    
    setState(() => _isUpdating = true);
    
    final response = await _vmsService.updateTrainingStatus(
      _volunteer!.id, 
      status,
      scheduledDate: scheduledDate,
    );
    
    setState(() {
      _isUpdating = false;
      if (response.isSuccess) {
        _volunteer = response.data;
        _showSuccess('Training status updated');
      } else {
        _showError(response.error ?? 'Failed to update status');
      }
    });
  }

  Future<void> _updateMentoringStatus(MentoringStatus status) async {
    if (_volunteer == null) return;
    
    setState(() => _isUpdating = true);
    
    final response = await _vmsService.updateMentoringStatus(_volunteer!.id, status);
    
    setState(() {
      _isUpdating = false;
      if (response.isSuccess) {
        _volunteer = response.data;
        _showSuccess('Mentoring status updated');
      } else {
        _showError(response.error ?? 'Failed to update status');
      }
    });
  }

  Future<void> _requestExit() async {
    if (_volunteer == null) return;
    
    final reason = await _showExitReasonDialog();
    
    setState(() => _isUpdating = true);
    
    final response = await _vmsService.requestExit(_volunteer!.id, reason: reason);
    
    setState(() {
      _isUpdating = false;
      if (response.isSuccess) {
        _volunteer = response.data;
        _showSuccess('Exit request initiated');
      } else {
        _showError(response.error ?? 'Failed to request exit');
      }
    });
  }

  Future<void> _navigateToHandover() async {
    if (_volunteer == null) return;
    
    final result = await Navigator.pushNamed(
      context,
      '/admin/vms/handover/${_volunteer!.id}',
      arguments: _volunteer,
    );
    
    if (result == true) {
      _loadVolunteerDetails();
    }
  }

  Future<void> _finalizeExit() async {
    if (_volunteer == null) return;
    
    final confirmed = await _showConfirmDialog(
      'Finalize Exit',
      'Are you sure you want to finalize the exit for ${_volunteer!.displayName}? This action cannot be undone.',
    );
    
    if (confirmed != true) return;
    
    setState(() => _isUpdating = true);
    
    final response = await _vmsService.finalizeExit(_volunteer!.id);
    
    setState(() {
      _isUpdating = false;
      if (response.isSuccess) {
        _volunteer = response.data;
        _showSuccess('Exit finalized successfully');
      } else {
        _showError(response.error ?? 'Failed to finalize exit');
      }
    });
  }

  Future<void> _issueCertificate() async {
    if (_volunteer == null) return;
    
    final confirmed = await _showConfirmDialog(
      'Issue Certificate',
      'Are you sure you want to issue a certificate to ${_volunteer!.displayName}?',
    );
    
    if (confirmed != true) return;
    
    setState(() => _isUpdating = true);
    
    final response = await _vmsService.issueCertificate(_volunteer!.id);
    
    setState(() {
      _isUpdating = false;
      if (response.isSuccess) {
        _volunteer = response.data;
        _showSuccess('Certificate issued successfully');
      } else {
        _showError(response.error ?? 'Failed to issue certificate');
      }
    });
  }

  Future<DateTime?> _selectDate() async {
    return showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
  }

  Future<String?> _showExitReasonDialog() async {
    String reason = '';
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Exit Reason',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          onChanged: (value) => reason = value,
          decoration: InputDecoration(
            hintText: 'Enter reason for exit (optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reason),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
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
          _volunteer?.volunteerCode ?? 'Volunteer Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadVolunteerDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || _volunteer == null
              ? _buildErrorState()
              : Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: _loadVolunteerDetails,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Card
                            _buildHeaderCard(),
                            const SizedBox(height: 20),
                            
                            // Lifecycle Progress
                            LifecycleProgressIndicator(volunteer: _volunteer!),
                            const SizedBox(height: 20),
                            
                            // Status Management
                            _buildStatusManagement(),
                            const SizedBox(height: 20),
                            
                            // Action Buttons
                            _buildActionButtons(),
                            const SizedBox(height: 20),
                            
                            // Contact Information
                            _buildContactInfo(),
                            const SizedBox(height: 20),
                            
                            // Handover Details (if applicable)
                            if (_volunteer!.handoverDetails?.isComplete == true)
                              _buildHandoverDetails(),
                            
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                    
                    // Loading overlay
                    if (_isUpdating)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error Loading Volunteer',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Volunteer not found',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadVolunteerDetails,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Profile Picture
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: _volunteer!.photoUrl != null
                      ? NetworkImage(_volunteer!.photoUrl!)
                      : null,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: _volunteer!.photoUrl == null
                      ? const Icon(Icons.person_rounded, size: 40, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              
              // Volunteer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Volunteer Code
                    if (_volunteer!.volunteerCode != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _volunteer!.volunteerCode!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    
                    // Name
                    Text(
                      _volunteer!.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    
                    // Duration
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          'Volunteering: ${_volunteer!.durationDisplay}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stage Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getStageIcon(_volunteer!.currentStage),
                  size: 20,
                  color: StageFilterDropdown.getStageColor(_volunteer!.currentStage),
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Stage: ${_volunteer!.currentStage.displayName}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: StageFilterDropdown.getStageColor(_volunteer!.currentStage),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStageIcon(VolunteerStage stage) {
    switch (stage) {
      case VolunteerStage.onboarding:
        return Icons.person_add_rounded;
      case VolunteerStage.training:
        return Icons.school_rounded;
      case VolunteerStage.mentoring:
        return Icons.groups_rounded;
      case VolunteerStage.exitPending:
        return Icons.logout_rounded;
      case VolunteerStage.exited:
        return Icons.exit_to_app_rounded;
      case VolunteerStage.certificateEligible:
        return Icons.workspace_premium_rounded;
      case VolunteerStage.certificateIssued:
        return Icons.card_membership_rounded;
    }
  }

  Widget _buildStatusManagement() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Management',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Onboarding Status
          OnboardingStatusDropdown(
            value: _volunteer!.onboardingStatus,
            onChanged: _updateOnboardingStatus,
            enabled: _volunteer!.exitStatus == ExitStatus.none,
          ),
          const SizedBox(height: 16),
          
          // Training Status
          TrainingStatusDropdown(
            value: _volunteer!.trainingStatus,
            onChanged: _updateTrainingStatus,
            enabled: _volunteer!.onboardingStatus == OnboardingStatus.completed &&
                     _volunteer!.exitStatus == ExitStatus.none,
          ),
          if (_volunteer!.trainingScheduledDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Scheduled: ${_formatDate(_volunteer!.trainingScheduledDate!)}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 16),
          
          // Mentoring Status
          MentoringStatusDropdown(
            value: _volunteer!.mentoringStatus,
            onChanged: _updateMentoringStatus,
            enabled: _volunteer!.trainingStatus == TrainingStatus.completed &&
                     _volunteer!.exitStatus == ExitStatus.none,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Exit Request Button
          if (_volunteer!.exitStatus == ExitStatus.none &&
              _volunteer!.mentoringStatus == MentoringStatus.active)
            _buildActionTile(
              'Request Exit',
              'Initiate the exit process for this volunteer',
              Icons.logout_rounded,
              Colors.orange,
              _requestExit,
            ),
          
          // Handover Button
          if (_volunteer!.exitStatus == ExitStatus.requested ||
              _volunteer!.exitStatus == ExitStatus.handoverPending)
            _buildActionTile(
              'Complete Handover',
              'Record handover details for mentored child',
              Icons.assignment_turned_in_rounded,
              Colors.blue,
              _navigateToHandover,
            ),
          
          // Finalize Exit Button
          if (_volunteer!.exitStatus == ExitStatus.handoverCompleted)
            _buildActionTile(
              'Finalize Exit',
              'Complete the exit process',
              Icons.exit_to_app_rounded,
              Colors.red,
              _finalizeExit,
            ),
          
          // Issue Certificate Button
          if (_volunteer!.canIssueCertificate)
            _buildActionTile(
              'Issue Certificate',
              'Issue a completion certificate',
              Icons.card_membership_rounded,
              Colors.green,
              _issueCertificate,
            ),
          
          // Certificate Issued Badge
          if (_volunteer!.certificateIssued)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: Colors.green, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Certificate Issued',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        if (_volunteer!.certificateIssuedDate != null)
                          Text(
                            'Issued on: ${_formatDate(_volunteer!.certificateIssuedDate!)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.green[700],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_volunteer!.email != null)
            _buildInfoRow(Icons.email_rounded, 'Email', _volunteer!.email!),
          if (_volunteer!.phone != null)
            _buildInfoRow(Icons.phone_rounded, 'Phone', _volunteer!.phone!),
          if (_volunteer!.currentLocation != null)
            _buildInfoRow(Icons.location_on_rounded, 'Location', _volunteer!.currentLocation!),
          if (_volunteer!.linkedIn != null)
            _buildInfoRow(Icons.link_rounded, 'LinkedIn', _volunteer!.linkedIn!),
          if (_volunteer!.emergencyContact != null)
            _buildInfoRow(
              Icons.emergency_rounded, 
              'Emergency Contact', 
              '${_volunteer!.emergencyContact} (${_volunteer!.emergencyRelation ?? 'N/A'})',
            ),
          if (_volunteer!.dateOfJoining != null)
            _buildInfoRow(
              Icons.calendar_today_rounded, 
              'Date of Joining', 
              _formatDate(_volunteer!.dateOfJoining!),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandoverDetails() {
    final handover = _volunteer!.handoverDetails!;
    
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_turned_in_rounded, color: Colors.teal),
              const SizedBox(width: 8),
              Text(
                'Handover Details',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(Icons.child_care_rounded, 'Child Name', handover.childName ?? 'N/A'),
          if (handover.childCurrentStatus != null)
            _buildInfoRow(Icons.info_rounded, 'Child Status', handover.childCurrentStatus!),
          if (handover.handoverNotes != null)
            _buildInfoRow(Icons.notes_rounded, 'Notes', handover.handoverNotes!),
          if (handover.handoverDate != null)
            _buildInfoRow(Icons.event_rounded, 'Handover Date', _formatDate(handover.handoverDate!)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
