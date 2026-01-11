/// Model for VMS Dashboard statistics
class VMSDashboardStats {
  final int totalVolunteers;
  final int pendingApproval;
  final int inOnboarding;
  final int inTraining;
  final int activeMentoring;
  final int exitPending;
  final int exited;
  final int certificateEligible;
  final int certificateIssued;
  
  // Additional stats
  final int totalActiveVolunteers;
  final double averageDurationMonths;

  VMSDashboardStats({
    this.totalVolunteers = 0,
    this.pendingApproval = 0,
    this.inOnboarding = 0,
    this.inTraining = 0,
    this.activeMentoring = 0,
    this.exitPending = 0,
    this.exited = 0,
    this.certificateEligible = 0,
    this.certificateIssued = 0,
    this.totalActiveVolunteers = 0,
    this.averageDurationMonths = 0.0,
  });

  factory VMSDashboardStats.fromJson(Map<String, dynamic> json) {
    return VMSDashboardStats(
      totalVolunteers: _parseInt(json['totalVolunteers']),
      pendingApproval: _parseInt(json['pendingApproval']),
      inOnboarding: _parseInt(json['inOnboarding']),
      inTraining: _parseInt(json['inTraining']),
      activeMentoring: _parseInt(json['activeMentoring']),
      exitPending: _parseInt(json['exitPending']),
      exited: _parseInt(json['exited']),
      certificateEligible: _parseInt(json['certificateEligible']),
      certificateIssued: _parseInt(json['certificateIssued']),
      totalActiveVolunteers: _parseInt(json['totalActiveVolunteers']),
      averageDurationMonths: _parseDouble(json['averageDurationMonths']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalVolunteers': totalVolunteers,
      'pendingApproval': pendingApproval,
      'inOnboarding': inOnboarding,
      'inTraining': inTraining,
      'activeMentoring': activeMentoring,
      'exitPending': exitPending,
      'exited': exited,
      'certificateEligible': certificateEligible,
      'certificateIssued': certificateIssued,
      'totalActiveVolunteers': totalActiveVolunteers,
      'averageDurationMonths': averageDurationMonths,
    };
  }

  /// Get list of stats for display in dashboard cards
  List<DashboardStatItem> get statItems => [
    DashboardStatItem(
      title: 'Total Volunteers',
      value: totalVolunteers,
      icon: 'people',
      color: DashboardStatColor.blue,
    ),
    DashboardStatItem(
      title: 'Pending Approval',
      value: pendingApproval,
      icon: 'pending',
      color: DashboardStatColor.orange,
    ),
    DashboardStatItem(
      title: 'In Onboarding',
      value: inOnboarding,
      icon: 'person_add',
      color: DashboardStatColor.purple,
    ),
    DashboardStatItem(
      title: 'In Training',
      value: inTraining,
      icon: 'school',
      color: DashboardStatColor.teal,
    ),
    DashboardStatItem(
      title: 'Active Mentoring',
      value: activeMentoring,
      icon: 'groups',
      color: DashboardStatColor.green,
    ),
    DashboardStatItem(
      title: 'Exit Pending',
      value: exitPending,
      icon: 'logout',
      color: DashboardStatColor.red,
    ),
    DashboardStatItem(
      title: 'Certificate Eligible',
      value: certificateEligible,
      icon: 'workspace_premium',
      color: DashboardStatColor.amber,
    ),
    DashboardStatItem(
      title: 'Certificates Issued',
      value: certificateIssued,
      icon: 'card_membership',
      color: DashboardStatColor.indigo,
    ),
  ];

  @override
  String toString() {
    return 'VMSDashboardStats(total: $totalVolunteers, active: $totalActiveVolunteers, pending: $pendingApproval)';
  }
}

/// Color options for dashboard stat cards
enum DashboardStatColor {
  blue,
  orange,
  purple,
  teal,
  green,
  red,
  amber,
  indigo,
  pink,
  cyan,
}

/// Individual stat item for dashboard display
class DashboardStatItem {
  final String title;
  final int value;
  final String icon;
  final DashboardStatColor color;
  final String? subtitle;

  DashboardStatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });
}
