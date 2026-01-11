import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/volunteer_model.dart';

/// Dropdown for Onboarding Status
class OnboardingStatusDropdown extends StatelessWidget {
  final OnboardingStatus value;
  final ValueChanged<OnboardingStatus> onChanged;
  final bool enabled;

  const OnboardingStatusDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return _StatusDropdown<OnboardingStatus>(
      value: value,
      items: OnboardingStatus.values,
      onChanged: enabled ? onChanged : null,
      getDisplayName: (status) => status.displayName,
      getColor: (status) => _getOnboardingColor(status),
      label: 'Onboarding Status',
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
}

/// Dropdown for Training Status
class TrainingStatusDropdown extends StatelessWidget {
  final TrainingStatus value;
  final ValueChanged<TrainingStatus> onChanged;
  final bool enabled;

  const TrainingStatusDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return _StatusDropdown<TrainingStatus>(
      value: value,
      items: TrainingStatus.values,
      onChanged: enabled ? onChanged : null,
      getDisplayName: (status) => status.displayName,
      getColor: (status) => _getTrainingColor(status),
      label: 'Training Status',
    );
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
}

/// Dropdown for Mentoring Status
class MentoringStatusDropdown extends StatelessWidget {
  final MentoringStatus value;
  final ValueChanged<MentoringStatus> onChanged;
  final bool enabled;

  const MentoringStatusDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return _StatusDropdown<MentoringStatus>(
      value: value,
      items: MentoringStatus.values,
      onChanged: enabled ? onChanged : null,
      getDisplayName: (status) => status.displayName,
      getColor: (status) => _getMentoringColor(status),
      label: 'Mentoring Status',
    );
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
}

/// Dropdown for Stage Filter
class StageFilterDropdown extends StatelessWidget {
  final VolunteerStage? value;
  final ValueChanged<VolunteerStage?> onChanged;
  final bool showAllOption;

  const StageFilterDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.showAllOption = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<VolunteerStage?>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF2C3E50),
            fontWeight: FontWeight.w500,
          ),
          hint: Text(
            'Filter by Stage',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          items: [
            if (showAllOption)
              DropdownMenuItem<VolunteerStage?>(
                value: null,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('All Stages'),
                  ],
                ),
              ),
            ...VolunteerStage.values.map((stage) {
              return DropdownMenuItem<VolunteerStage?>(
                value: stage,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: getStageColor(stage),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(stage.displayName),
                  ],
                ),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  static Color getStageColor(VolunteerStage stage) {
    switch (stage) {
      case VolunteerStage.onboarding:
        return Colors.purple;
      case VolunteerStage.training:
        return Colors.blue;
      case VolunteerStage.mentoring:
        return Colors.teal;
      case VolunteerStage.exitPending:
        return Colors.orange;
      case VolunteerStage.exited:
        return Colors.red;
      case VolunteerStage.certificateEligible:
        return Colors.amber[700]!;
      case VolunteerStage.certificateIssued:
        return Colors.green;
    }
  }
}

/// Generic status dropdown widget
class _StatusDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T>? onChanged;
  final String Function(T) getDisplayName;
  final Color Function(T) getColor;
  final String label;

  const _StatusDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.getDisplayName,
    required this.getColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: onChanged != null ? getColor(value).withOpacity(0.5) : Colors.grey[300]!,
            ),
            boxShadow: [
              BoxShadow(
                color: getColor(value).withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: onChanged != null ? getColor(value) : Colors.grey,
              ),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF2C3E50),
                fontWeight: FontWeight.w500,
              ),
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: getColor(item).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          getDisplayName(item),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: getColor(item),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged != null
                  ? (newValue) {
                      if (newValue != null) {
                        onChanged!(newValue);
                      }
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// Status chip widget for displaying status inline
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool small;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.small = false,
  });

  factory StatusChip.fromOnboardingStatus(OnboardingStatus status, {bool small = false}) {
    return StatusChip(
      label: status.displayName,
      color: _getOnboardingColor(status),
      icon: _getOnboardingIcon(status),
      small: small,
    );
  }

  factory StatusChip.fromTrainingStatus(TrainingStatus status, {bool small = false}) {
    return StatusChip(
      label: status.displayName,
      color: _getTrainingColor(status),
      icon: _getTrainingIcon(status),
      small: small,
    );
  }

  factory StatusChip.fromMentoringStatus(MentoringStatus status, {bool small = false}) {
    return StatusChip(
      label: status.displayName,
      color: _getMentoringColor(status),
      icon: _getMentoringIcon(status),
      small: small,
    );
  }

  factory StatusChip.fromStage(VolunteerStage stage, {bool small = false}) {
    return StatusChip(
      label: stage.displayName,
      color: StageFilterDropdown.getStageColor(stage),
      icon: _getStageIcon(stage),
      small: small,
    );
  }

  static Color _getOnboardingColor(OnboardingStatus status) {
    switch (status) {
      case OnboardingStatus.notStarted:
        return Colors.grey;
      case OnboardingStatus.inProgress:
        return Colors.orange;
      case OnboardingStatus.completed:
        return Colors.green;
    }
  }

  static IconData _getOnboardingIcon(OnboardingStatus status) {
    switch (status) {
      case OnboardingStatus.notStarted:
        return Icons.hourglass_empty;
      case OnboardingStatus.inProgress:
        return Icons.pending;
      case OnboardingStatus.completed:
        return Icons.check_circle;
    }
  }

  static Color _getTrainingColor(TrainingStatus status) {
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

  static IconData _getTrainingIcon(TrainingStatus status) {
    switch (status) {
      case TrainingStatus.notStarted:
        return Icons.hourglass_empty;
      case TrainingStatus.scheduled:
        return Icons.event;
      case TrainingStatus.inProgress:
        return Icons.school;
      case TrainingStatus.completed:
        return Icons.check_circle;
    }
  }

  static Color _getMentoringColor(MentoringStatus status) {
    switch (status) {
      case MentoringStatus.notMentoring:
        return Colors.grey;
      case MentoringStatus.active:
        return Colors.teal;
      case MentoringStatus.completed:
        return Colors.green;
    }
  }

  static IconData _getMentoringIcon(MentoringStatus status) {
    switch (status) {
      case MentoringStatus.notMentoring:
        return Icons.person_off;
      case MentoringStatus.active:
        return Icons.groups;
      case MentoringStatus.completed:
        return Icons.check_circle;
    }
  }

  static IconData _getStageIcon(VolunteerStage stage) {
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

  @override
  Widget build(BuildContext context) {
    final double fontSize = small ? 10 : 12;
    final double iconSize = small ? 12 : 14;
    final EdgeInsets padding = small 
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 6);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(small ? 8 : 12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: color),
            SizedBox(width: small ? 4 : 6),
          ],
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
