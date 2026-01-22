import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/volunteer_model.dart';
import '../config/app_colors.dart';

/// Widget that displays the lifecycle progress as a stepper/checklist
class LifecycleProgressIndicator extends StatelessWidget {
  final Volunteer volunteer;
  final bool compact;

  const LifecycleProgressIndicator({
    super.key,
    required this.volunteer,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final stages = _buildStages();
    
    if (compact) {
      return _buildCompactIndicator(stages);
    }
    
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
            'Lifecycle Progress',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 20),
          ...stages.asMap().entries.map((entry) {
            final index = entry.key;
            final stage = entry.value;
            final isLast = index == stages.length - 1;
            
            return _buildStageItem(stage, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildCompactIndicator(List<_StageItem> stages) {
    return Row(
      children: stages.asMap().entries.map((entry) {
        final index = entry.key;
        final stage = entry.value;
        final isLast = index == stages.length - 1;
        
        return Expanded(
          child: Row(
            children: [
              _buildCompactStageCircle(stage),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    color: stage.isCompleted 
                        ? Colors.green 
                        : Colors.grey[300],
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactStageCircle(_StageItem stage) {
    return Tooltip(
      message: '${stage.title}: ${stage.status}',
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: stage.isCompleted 
              ? Colors.green 
              : stage.isActive 
                  ? stage.color 
                  : Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: Icon(
          stage.isCompleted ? Icons.check : stage.icon,
          size: 14,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStageItem(_StageItem stage, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            // Stage circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: stage.isCompleted 
                    ? Colors.green 
                    : stage.isActive 
                        ? stage.color 
                        : Colors.grey[300],
                shape: BoxShape.circle,
                boxShadow: stage.isActive
                    ? [
                        BoxShadow(
                          color: stage.color.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                stage.isCompleted ? Icons.check_rounded : stage.icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            // Connecting line
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: stage.isCompleted ? Colors.green : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      stage.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: stage.isActive 
                            ? stage.color 
                            : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: stage.isCompleted 
                            ? Colors.green.withOpacity(0.1)
                            : stage.isActive 
                                ? stage.color.withOpacity(0.1)
                                : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        stage.status,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: stage.isCompleted 
                              ? Colors.green
                              : stage.isActive 
                                  ? stage.color
                                  : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                if (stage.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    stage.subtitle!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.gray1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<_StageItem> _buildStages() {
    final stages = <_StageItem>[];
    
    // Onboarding stage
    final onboardingCompleted = volunteer.onboardingStatus == OnboardingStatus.completed;
    stages.add(_StageItem(
      title: 'Onboarding',
      status: volunteer.onboardingStatus.displayName,
      icon: Icons.person_add_rounded,
      color: Colors.purple,
      isCompleted: onboardingCompleted,
      isActive: !onboardingCompleted && volunteer.currentStage == VolunteerStage.onboarding,
    ));
    
    // Training stage
    final trainingCompleted = volunteer.trainingStatus == TrainingStatus.completed;
    String? trainingSubtitle;
    if (volunteer.trainingScheduledDate != null && volunteer.trainingStatus == TrainingStatus.scheduled) {
      trainingSubtitle = 'Scheduled: ${_formatDate(volunteer.trainingScheduledDate!)}';
    }
    stages.add(_StageItem(
      title: 'Training',
      status: volunteer.trainingStatus.displayName,
      icon: Icons.school_rounded,
      color: Colors.blue,
      isCompleted: trainingCompleted,
      isActive: onboardingCompleted && !trainingCompleted && volunteer.currentStage == VolunteerStage.training,
      subtitle: trainingSubtitle,
    ));
    
    // Mentoring stage
    final mentoringCompleted = volunteer.mentoringStatus == MentoringStatus.completed;
    final mentoringActive = volunteer.mentoringStatus == MentoringStatus.active;
    stages.add(_StageItem(
      title: 'Mentoring',
      status: volunteer.mentoringStatus.displayName,
      icon: Icons.groups_rounded,
      color: Colors.teal,
      isCompleted: mentoringCompleted,
      isActive: mentoringActive,
      subtitle: mentoringActive ? 'Currently mentoring a child' : null,
    ));
    
    // Exit stage (if applicable)
    if (volunteer.exitStatus != ExitStatus.none) {
      final exitCompleted = volunteer.exitStatus == ExitStatus.exited;
      String? exitSubtitle;
      if (volunteer.handoverDetails?.isComplete == true) {
        exitSubtitle = 'Handover: ${volunteer.handoverDetails?.childName}';
      }
      stages.add(_StageItem(
        title: 'Exit Process',
        status: volunteer.exitStatus.displayName,
        icon: Icons.logout_rounded,
        color: Colors.orange,
        isCompleted: exitCompleted,
        isActive: !exitCompleted && volunteer.currentStage == VolunteerStage.exitPending,
        subtitle: exitSubtitle,
      ));
    }
    
    // Certificate stage (if eligible or issued)
    if (volunteer.certificateEligible || volunteer.certificateIssued) {
      stages.add(_StageItem(
        title: 'Certificate',
        status: volunteer.certificateIssued ? 'Issued' : 'Eligible',
        icon: volunteer.certificateIssued ? Icons.card_membership : Icons.workspace_premium,
        color: volunteer.certificateIssued ? Colors.green : Colors.amber[700]!,
        isCompleted: volunteer.certificateIssued,
        isActive: volunteer.certificateEligible && !volunteer.certificateIssued,
        subtitle: volunteer.certificateIssuedDate != null 
            ? 'Issued on: ${_formatDate(volunteer.certificateIssuedDate!)}'
            : null,
      ));
    }
    
    return stages;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StageItem {
  final String title;
  final String status;
  final IconData icon;
  final Color color;
  final bool isCompleted;
  final bool isActive;
  final String? subtitle;

  _StageItem({
    required this.title,
    required this.status,
    required this.icon,
    required this.color,
    required this.isCompleted,
    required this.isActive,
    this.subtitle,
  });
}
