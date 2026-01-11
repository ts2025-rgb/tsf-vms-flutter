import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/volunteer_model.dart';
import 'status_dropdowns.dart';

/// Modern volunteer card with VMS fields
class VMSVolunteerCard extends StatelessWidget {
  final Volunteer volunteer;
  final VoidCallback? onTap;
  final bool showActions;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const VMSVolunteerCard({
    super.key,
    required this.volunteer,
    this.onTap,
    this.showActions = false,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Volunteer Code Badge
                if (volunteer.volunteerCode != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildVolunteerCodeBadge(),
                      _buildDurationBadge(),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                
                Row(
                  children: [
                    // Profile Picture with status indicator
                    _buildProfilePicture(),
                    const SizedBox(width: 16),
                    
                    // Volunteer Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            volunteer.displayName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: const Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (volunteer.email != null)
                            Text(
                              volunteer.email!,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF7F8C8D),
                              ),
                            ),
                          if (volunteer.phone != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              volunteer.phone!,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF7F8C8D),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          _buildLocationAndStatus(),
                        ],
                      ),
                    ),
                    
                    // Arrow Icon
                    if (onTap != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                  ],
                ),
                
                // Lifecycle Status Chips
                const SizedBox(height: 16),
                _buildLifecycleStatusRow(),
                
                // Certificate indicator
                if (volunteer.certificateEligible || volunteer.certificateIssued) ...[
                  const SizedBox(height: 12),
                  _buildCertificateIndicator(),
                ],
                
                // Action buttons
                if (showActions) ...[
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'Approve',
                          Icons.check_circle_rounded,
                          Colors.green,
                          onApprove,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          'Reject',
                          Icons.cancel_rounded,
                          Colors.red,
                          onReject,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVolunteerCodeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E88E5),
            const Color(0xFF1565C0),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.badge_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            volunteer.volunteerCode ?? '',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationBadge() {
    final duration = volunteer.durationDisplay;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF26A69A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF26A69A).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF26A69A)),
          const SizedBox(width: 6),
          Text(
            duration,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF26A69A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePicture() {
    final stageColor = StageFilterDropdown.getStageColor(volunteer.currentStage);
    
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: stageColor, width: 3),
          ),
          child: CircleAvatar(
            radius: 32,
            backgroundImage: volunteer.photoUrl != null
                ? NetworkImage(volunteer.photoUrl!)
                : null,
            backgroundColor: const Color(0xFF1E88E5).withOpacity(0.1),
            child: volunteer.photoUrl == null
                ? const Icon(
                    Icons.person_rounded,
                    size: 32,
                    color: Color(0xFF1E88E5),
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: stageColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(
              _getStageIcon(volunteer.currentStage),
              size: 10,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getStageIcon(VolunteerStage stage) {
    switch (stage) {
      case VolunteerStage.onboarding:
        return Icons.person_add;
      case VolunteerStage.training:
        return Icons.school;
      case VolunteerStage.mentoring:
        return Icons.groups;
      case VolunteerStage.exitPending:
        return Icons.logout;
      case VolunteerStage.exited:
        return Icons.exit_to_app;
      case VolunteerStage.certificateEligible:
        return Icons.workspace_premium;
      case VolunteerStage.certificateIssued:
        return Icons.card_membership;
    }
  }

  Widget _buildLocationAndStatus() {
    return Row(
      children: [
        if (volunteer.currentLocation != null) ...[
          Icon(Icons.location_on_rounded, size: 14, color: const Color(0xFF7F8C8D)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              volunteer.currentLocation!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF7F8C8D),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
        ],
        StatusChip.fromStage(volunteer.currentStage, small: true),
      ],
    );
  }

  Widget _buildLifecycleStatusRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildMiniStatusChip(
            'Onboarding',
            volunteer.onboardingStatus.displayName,
            _getOnboardingColor(volunteer.onboardingStatus),
          ),
          const SizedBox(width: 8),
          _buildMiniStatusChip(
            'Training',
            volunteer.trainingStatus.displayName,
            _getTrainingColor(volunteer.trainingStatus),
          ),
          const SizedBox(width: 8),
          _buildMiniStatusChip(
            'Mentoring',
            volunteer.mentoringStatus.displayName,
            _getMentoringColor(volunteer.mentoringStatus),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatusChip(String label, String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _getOnboardingColor(OnboardingStatus status) {
    switch (status) {
      case OnboardingStatus.notStarted:
        return Colors.grey;
      case OnboardingStatus.inProgress:
        return Colors.orange;
      case OnboardingStatus.completed:
        return Colors.green;
    }
  }

  Color _getTrainingColor(TrainingStatus status) {
    switch (status) {
      case TrainingStatus.notStarted:
        return Colors.grey;
      case TrainingStatus.scheduled:
        return Colors.blue;
      case TrainingStatus.inProgress:
        return Colors.orange;
      case TrainingStatus.completed:
        return Colors.green;
    }
  }

  Color _getMentoringColor(MentoringStatus status) {
    switch (status) {
      case MentoringStatus.notMentoring:
        return Colors.grey;
      case MentoringStatus.active:
        return Colors.teal;
      case MentoringStatus.completed:
        return Colors.green;
    }
  }

  Widget _buildCertificateIndicator() {
    final isIssued = volunteer.certificateIssued;
    final color = isIssued ? Colors.green : Colors.amber[700]!;
    final label = isIssued ? 'Certificate Issued' : 'Certificate Eligible';
    final icon = isIssued ? Icons.card_membership : Icons.workspace_premium;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (isIssued && volunteer.certificateIssuedDate != null) ...[
            const SizedBox(width: 8),
            Text(
              '• ${_formatDate(volunteer.certificateIssuedDate!)}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }
}
