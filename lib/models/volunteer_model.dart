import 'handover_details_model.dart';

/// Enum for onboarding status
enum OnboardingStatus {
  notStarted('not_started', 'Not Started'),
  inProgress('in_progress', 'In Progress'),
  completed('completed', 'Completed');

  final String value;
  final String displayName;
  const OnboardingStatus(this.value, this.displayName);

  static OnboardingStatus fromString(String? value) {
    return OnboardingStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OnboardingStatus.notStarted,
    );
  }
}

/// Enum for training status
enum TrainingStatus {
  notStarted('not_started', 'Not Started'),
  scheduled('scheduled', 'Scheduled'),
  inProgress('in_progress', 'In Progress'),
  completed('completed', 'Completed');

  final String value;
  final String displayName;
  const TrainingStatus(this.value, this.displayName);

  static TrainingStatus fromString(String? value) {
    return TrainingStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TrainingStatus.notStarted,
    );
  }
}

/// Enum for mentoring status
enum MentoringStatus {
  notMentoring('not_mentoring', 'Not Mentoring'),
  active('active', 'Active'),
  completed('completed', 'Completed');

  final String value;
  final String displayName;
  const MentoringStatus(this.value, this.displayName);

  static MentoringStatus fromString(String? value) {
    return MentoringStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MentoringStatus.notMentoring,
    );
  }
}

/// Enum for exit status
enum ExitStatus {
  none('none', 'None'),
  requested('requested', 'Exit Requested'),
  handoverPending('handover_pending', 'Handover Pending'),
  handoverCompleted('handover_completed', 'Handover Completed'),
  exited('exited', 'Exited');

  final String value;
  final String displayName;
  const ExitStatus(this.value, this.displayName);

  static ExitStatus fromString(String? value) {
    return ExitStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ExitStatus.none,
    );
  }
}

/// Enum for volunteer lifecycle stages (for filtering)
enum VolunteerStage {
  onboarding('onboarding', 'Onboarding'),
  training('training', 'Training'),
  mentoring('mentoring', 'Mentoring'),
  exitPending('exit-pending', 'Exit Pending'),
  exited('exited', 'Exited'),
  certificateEligible('certificate-eligible', 'Certificate Eligible'),
  certificateIssued('certificate-issued', 'Certificate Issued');

  final String value;
  final String displayName;
  const VolunteerStage(this.value, this.displayName);

  static VolunteerStage fromString(String? value) {
    return VolunteerStage.values.firstWhere(
      (e) => e.value == value,
      orElse: () => VolunteerStage.onboarding,
    );
  }
}

/// Complete Volunteer model with all VMS fields
class Volunteer {
  final String id;
  final String? volunteerCode;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final String? currentLocation;
  final String? approvalStatus;
  
  // VMS Lifecycle fields
  final DateTime? dateOfJoining;
  final DateTime? dateOfExit;
  final OnboardingStatus onboardingStatus;
  final TrainingStatus trainingStatus;
  final DateTime? trainingScheduledDate;
  final MentoringStatus mentoringStatus;
  final ExitStatus exitStatus;
  final String? exitReason;
  final HandoverDetails? handoverDetails;
  
  // Certificate fields
  final bool certificateEligible;
  final bool certificateIssued;
  final DateTime? certificateIssuedDate;
  
  // Duration fields
  final int? volunteeringDurationDays;
  final int? volunteeringDurationMonths;
  
  // Other existing fields
  final List<String>? skills;
  final List<String>? preferredRoles;
  final String? linkedIn;
  final String? emergencyContact;
  final String? emergencyRelation;

  Volunteer({
    required this.id,
    this.volunteerCode,
    this.firstName,
    this.lastName,
    this.fullName,
    this.email,
    this.phone,
    this.photoUrl,
    this.currentLocation,
    this.approvalStatus,
    this.dateOfJoining,
    this.dateOfExit,
    this.onboardingStatus = OnboardingStatus.notStarted,
    this.trainingStatus = TrainingStatus.notStarted,
    this.trainingScheduledDate,
    this.mentoringStatus = MentoringStatus.notMentoring,
    this.exitStatus = ExitStatus.none,
    this.exitReason,
    this.handoverDetails,
    this.certificateEligible = false,
    this.certificateIssued = false,
    this.certificateIssuedDate,
    this.volunteeringDurationDays,
    this.volunteeringDurationMonths,
    this.skills,
    this.preferredRoles,
    this.linkedIn,
    this.emergencyContact,
    this.emergencyRelation,
  });

  factory Volunteer.fromJson(Map<String, dynamic> json) {
    return Volunteer(
      id: json['_id'] ?? json['id'] ?? '',
      volunteerCode: json['volunteerCode'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      fullName: json['fullName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      photoUrl: json['photoUrl'] as String?,
      currentLocation: json['currentLocation'] as String?,
      approvalStatus: json['approvalStatus'] as String?,
      dateOfJoining: json['dateOfJoining'] != null 
          ? DateTime.tryParse(json['dateOfJoining'].toString()) 
          : null,
      dateOfExit: json['dateOfExit'] != null 
          ? DateTime.tryParse(json['dateOfExit'].toString()) 
          : null,
      onboardingStatus: OnboardingStatus.fromString(json['onboardingStatus'] as String?),
      trainingStatus: TrainingStatus.fromString(json['trainingStatus'] as String?),
      trainingScheduledDate: json['trainingScheduledDate'] != null 
          ? DateTime.tryParse(json['trainingScheduledDate'].toString()) 
          : null,
      mentoringStatus: MentoringStatus.fromString(json['mentoringStatus'] as String?),
      exitStatus: ExitStatus.fromString(json['exitStatus'] as String?),
      exitReason: json['exitReason'] as String?,
      handoverDetails: json['handoverDetails'] != null 
          ? HandoverDetails.fromJson(json['handoverDetails'] as Map<String, dynamic>) 
          : null,
      certificateEligible: json['certificateEligible'] == true,
      certificateIssued: json['certificateIssued'] == true,
      certificateIssuedDate: json['certificateIssuedDate'] != null 
          ? DateTime.tryParse(json['certificateIssuedDate'].toString()) 
          : null,
      volunteeringDurationDays: json['volunteeringDurationDays'] as int?,
      volunteeringDurationMonths: json['volunteeringDurationMonths'] as int?,
      skills: json['skills'] != null 
          ? List<String>.from(json['skills']) 
          : null,
      preferredRoles: json['preferredRoles'] != null 
          ? List<String>.from(json['preferredRoles']) 
          : null,
      linkedIn: json['linkedIn'] as String?,
      emergencyContact: json['emergencyContact'] as String?,
      emergencyRelation: json['emergencyRelation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      if (volunteerCode != null) 'volunteerCode': volunteerCode,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (fullName != null) 'fullName': fullName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (currentLocation != null) 'currentLocation': currentLocation,
      if (approvalStatus != null) 'approvalStatus': approvalStatus,
      if (dateOfJoining != null) 'dateOfJoining': dateOfJoining!.toIso8601String(),
      if (dateOfExit != null) 'dateOfExit': dateOfExit!.toIso8601String(),
      'onboardingStatus': onboardingStatus.value,
      'trainingStatus': trainingStatus.value,
      if (trainingScheduledDate != null) 'trainingScheduledDate': trainingScheduledDate!.toIso8601String(),
      'mentoringStatus': mentoringStatus.value,
      'exitStatus': exitStatus.value,
      if (exitReason != null) 'exitReason': exitReason,
      if (handoverDetails != null) 'handoverDetails': handoverDetails!.toJson(),
      'certificateEligible': certificateEligible,
      'certificateIssued': certificateIssued,
      if (certificateIssuedDate != null) 'certificateIssuedDate': certificateIssuedDate!.toIso8601String(),
      if (volunteeringDurationDays != null) 'volunteeringDurationDays': volunteeringDurationDays,
      if (volunteeringDurationMonths != null) 'volunteeringDurationMonths': volunteeringDurationMonths,
      if (skills != null) 'skills': skills,
      if (preferredRoles != null) 'preferredRoles': preferredRoles,
      if (linkedIn != null) 'linkedIn': linkedIn,
      if (emergencyContact != null) 'emergencyContact': emergencyContact,
      if (emergencyRelation != null) 'emergencyRelation': emergencyRelation,
    };
  }

  /// Get display name (prefers fullName, then combines first+last)
  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    final parts = [firstName, lastName].where((p) => p != null && p.isNotEmpty);
    return parts.isEmpty ? 'Unknown' : parts.join(' ');
  }

  /// Get formatted duration string
  String get durationDisplay {
    if (volunteeringDurationMonths != null && volunteeringDurationMonths! > 0) {
      final months = volunteeringDurationMonths!;
      return months == 1 ? '1 month' : '$months months';
    }
    if (volunteeringDurationDays != null && volunteeringDurationDays! > 0) {
      final days = volunteeringDurationDays!;
      return days == 1 ? '1 day' : '$days days';
    }
    return 'New';
  }

  /// Get current lifecycle stage
  VolunteerStage get currentStage {
    if (certificateIssued) return VolunteerStage.certificateIssued;
    if (certificateEligible) return VolunteerStage.certificateEligible;
    if (exitStatus == ExitStatus.exited) return VolunteerStage.exited;
    if (exitStatus != ExitStatus.none) return VolunteerStage.exitPending;
    if (mentoringStatus == MentoringStatus.active) return VolunteerStage.mentoring;
    if (trainingStatus != TrainingStatus.completed) return VolunteerStage.training;
    if (onboardingStatus != OnboardingStatus.completed) return VolunteerStage.onboarding;
    return VolunteerStage.mentoring;
  }

  /// Check if volunteer can be issued certificate
  bool get canIssueCertificate => certificateEligible && !certificateIssued;

  Volunteer copyWith({
    String? id,
    String? volunteerCode,
    String? firstName,
    String? lastName,
    String? fullName,
    String? email,
    String? phone,
    String? photoUrl,
    String? currentLocation,
    String? approvalStatus,
    DateTime? dateOfJoining,
    DateTime? dateOfExit,
    OnboardingStatus? onboardingStatus,
    TrainingStatus? trainingStatus,
    DateTime? trainingScheduledDate,
    MentoringStatus? mentoringStatus,
    ExitStatus? exitStatus,
    String? exitReason,
    HandoverDetails? handoverDetails,
    bool? certificateEligible,
    bool? certificateIssued,
    DateTime? certificateIssuedDate,
    int? volunteeringDurationDays,
    int? volunteeringDurationMonths,
    List<String>? skills,
    List<String>? preferredRoles,
    String? linkedIn,
    String? emergencyContact,
    String? emergencyRelation,
  }) {
    return Volunteer(
      id: id ?? this.id,
      volunteerCode: volunteerCode ?? this.volunteerCode,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      currentLocation: currentLocation ?? this.currentLocation,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      dateOfJoining: dateOfJoining ?? this.dateOfJoining,
      dateOfExit: dateOfExit ?? this.dateOfExit,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      trainingStatus: trainingStatus ?? this.trainingStatus,
      trainingScheduledDate: trainingScheduledDate ?? this.trainingScheduledDate,
      mentoringStatus: mentoringStatus ?? this.mentoringStatus,
      exitStatus: exitStatus ?? this.exitStatus,
      exitReason: exitReason ?? this.exitReason,
      handoverDetails: handoverDetails ?? this.handoverDetails,
      certificateEligible: certificateEligible ?? this.certificateEligible,
      certificateIssued: certificateIssued ?? this.certificateIssued,
      certificateIssuedDate: certificateIssuedDate ?? this.certificateIssuedDate,
      volunteeringDurationDays: volunteeringDurationDays ?? this.volunteeringDurationDays,
      volunteeringDurationMonths: volunteeringDurationMonths ?? this.volunteeringDurationMonths,
      skills: skills ?? this.skills,
      preferredRoles: preferredRoles ?? this.preferredRoles,
      linkedIn: linkedIn ?? this.linkedIn,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyRelation: emergencyRelation ?? this.emergencyRelation,
    );
  }

  @override
  String toString() {
    return 'Volunteer(id: $id, volunteerCode: $volunteerCode, displayName: $displayName, stage: ${currentStage.displayName})';
  }
}
