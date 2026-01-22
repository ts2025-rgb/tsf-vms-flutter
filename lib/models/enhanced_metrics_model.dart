/// Model for enhanced VMS dashboard metrics including call tracking,
/// mood, self-esteem, and gamification features

/// Time filter options for metrics
enum MetricsTimeFilter {
  threeDays('3days', 'Last 3 Days'),
  week('week', 'Last Week'),
  month('month', 'Last Month'),
  all('all', 'All Time');

  final String value;
  final String displayName;
  const MetricsTimeFilter(this.value, this.displayName);

  static MetricsTimeFilter fromString(String? value) {
    return MetricsTimeFilter.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MetricsTimeFilter.all,
    );
  }
}

/// Call Metrics Model
class CallMetrics {
  final int totalCalls;
  final CallFrequency callFrequency;
  final double totalCallHours;
  final double averageCallDuration;
  final CallsByTimeRange callsByTimeRange;

  CallMetrics({
    required this.totalCalls,
    required this.callFrequency,
    required this.totalCallHours,
    required this.averageCallDuration,
    required this.callsByTimeRange,
  });

  factory CallMetrics.fromJson(Map<String, dynamic> json) {
    return CallMetrics(
      totalCalls: json['totalCalls'] ?? 0,
      callFrequency: CallFrequency.fromJson(json['callFrequency'] ?? {}),
      totalCallHours: (json['totalCallHours'] ?? 0).toDouble(),
      averageCallDuration: (json['averageCallDuration'] ?? 0).toDouble(),
      callsByTimeRange: CallsByTimeRange.fromJson(
        json['callsByTimeRange'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCalls': totalCalls,
      'callFrequency': callFrequency.toJson(),
      'totalCallHours': totalCallHours,
      'averageCallDuration': averageCallDuration,
      'callsByTimeRange': callsByTimeRange.toJson(),
    };
  }
}

class CallFrequency {
  final double daily;
  final double weekly;
  final double monthly;

  CallFrequency({
    required this.daily,
    required this.weekly,
    required this.monthly,
  });

  factory CallFrequency.fromJson(Map<String, dynamic> json) {
    return CallFrequency(
      daily: (json['daily'] ?? 0).toDouble(),
      weekly: (json['weekly'] ?? 0).toDouble(),
      monthly: (json['monthly'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'daily': daily, 'weekly': weekly, 'monthly': monthly};
  }
}

class CallsByTimeRange {
  final int last3Days;
  final int lastWeek;
  final int lastMonth;

  CallsByTimeRange({
    required this.last3Days,
    required this.lastWeek,
    required this.lastMonth,
  });

  factory CallsByTimeRange.fromJson(Map<String, dynamic> json) {
    return CallsByTimeRange(
      last3Days: json['last3Days'] ?? 0,
      lastWeek: json['lastWeek'] ?? 0,
      lastMonth: json['lastMonth'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'last3Days': last3Days,
      'lastWeek': lastWeek,
      'lastMonth': lastMonth,
    };
  }
}

/// Mood Metrics Model
class MoodMetrics {
  final double averageMood;
  final String moodTrend;
  final MoodDistribution moodDistribution;
  final List<MoodTimePoint> moodOverTime;

  MoodMetrics({
    required this.averageMood,
    required this.moodTrend,
    required this.moodDistribution,
    required this.moodOverTime,
  });

  factory MoodMetrics.fromJson(Map<String, dynamic> json) {
    return MoodMetrics(
      averageMood: (json['averageMood'] ?? 0).toDouble(),
      moodTrend: json['moodTrend'] ?? 'stable',
      moodDistribution: MoodDistribution.fromJson(
        json['moodDistribution'] ?? {},
      ),
      moodOverTime:
          (json['moodOverTime'] as List?)
              ?.map((e) => MoodTimePoint.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageMood': averageMood,
      'moodTrend': moodTrend,
      'moodDistribution': moodDistribution.toJson(),
      'moodOverTime': moodOverTime.map((e) => e.toJson()).toList(),
    };
  }
}

class MoodDistribution {
  final int excellent;
  final int good;
  final int neutral;
  final int poor;

  MoodDistribution({
    required this.excellent,
    required this.good,
    required this.neutral,
    required this.poor,
  });

  factory MoodDistribution.fromJson(Map<String, dynamic> json) {
    return MoodDistribution(
      excellent: json['excellent'] ?? 0,
      good: json['good'] ?? 0,
      neutral: json['neutral'] ?? 0,
      poor: json['poor'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'excellent': excellent,
      'good': good,
      'neutral': neutral,
      'poor': poor,
    };
  }
}

class MoodTimePoint {
  final DateTime date;
  final double average;

  MoodTimePoint({required this.date, required this.average});

  factory MoodTimePoint.fromJson(Map<String, dynamic> json) {
    return MoodTimePoint(
      date: DateTime.parse(json['date']),
      average: (json['average'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date.toIso8601String(), 'average': average};
  }
}

/// Self-Esteem Metrics Model
class SelfEsteemMetrics {
  final double averageSelfEsteem;
  final String selfEsteemTrend;
  final List<SelfEsteemTimePoint> selfEsteemOverTime;
  final double improvementRate;

  SelfEsteemMetrics({
    required this.averageSelfEsteem,
    required this.selfEsteemTrend,
    required this.selfEsteemOverTime,
    required this.improvementRate,
  });

  factory SelfEsteemMetrics.fromJson(Map<String, dynamic> json) {
    return SelfEsteemMetrics(
      averageSelfEsteem: (json['averageSelfEsteem'] ?? 0).toDouble(),
      selfEsteemTrend: json['selfEsteemTrend'] ?? 'stable',
      selfEsteemOverTime:
          (json['selfEsteemOverTime'] as List?)
              ?.map((e) => SelfEsteemTimePoint.fromJson(e))
              .toList() ??
          [],
      improvementRate: (json['improvementRate'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageSelfEsteem': averageSelfEsteem,
      'selfEsteemTrend': selfEsteemTrend,
      'selfEsteemOverTime': selfEsteemOverTime.map((e) => e.toJson()).toList(),
      'improvementRate': improvementRate,
    };
  }
}

class SelfEsteemTimePoint {
  final DateTime date;
  final double score;

  SelfEsteemTimePoint({required this.date, required this.score});

  factory SelfEsteemTimePoint.fromJson(Map<String, dynamic> json) {
    return SelfEsteemTimePoint(
      date: DateTime.parse(json['date']),
      score: (json['score'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date.toIso8601String(), 'score': score};
  }
}

/// Call Quality Metrics Model
class CallQualityMetrics {
  final double averageQualityRating;
  final int totalRatedCalls;
  final QualityDistribution qualityDistribution;

  CallQualityMetrics({
    required this.averageQualityRating,
    required this.totalRatedCalls,
    required this.qualityDistribution,
  });

  factory CallQualityMetrics.fromJson(Map<String, dynamic> json) {
    return CallQualityMetrics(
      averageQualityRating: (json['averageQualityRating'] ?? 0).toDouble(),
      totalRatedCalls: json['totalRatedCalls'] ?? 0,
      qualityDistribution: QualityDistribution.fromJson(
        json['qualityDistribution'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageQualityRating': averageQualityRating,
      'totalRatedCalls': totalRatedCalls,
      'qualityDistribution': qualityDistribution.toJson(),
    };
  }
}

class QualityDistribution {
  final int fiveStar;
  final int fourStar;
  final int threeStar;
  final int twoStar;
  final int oneStar;

  QualityDistribution({
    required this.fiveStar,
    required this.fourStar,
    required this.threeStar,
    required this.twoStar,
    required this.oneStar,
  });

  factory QualityDistribution.fromJson(Map<String, dynamic> json) {
    return QualityDistribution(
      fiveStar: json['5star'] ?? 0,
      fourStar: json['4star'] ?? 0,
      threeStar: json['3star'] ?? 0,
      twoStar: json['2star'] ?? 0,
      oneStar: json['1star'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '5star': fiveStar,
      '4star': fourStar,
      '3star': threeStar,
      '2star': twoStar,
      '1star': oneStar,
    };
  }
}

/// Mentor Ratings Model
class MentorRatingsMetrics {
  final List<TopRatedMentor> topRatedMentors;
  final double overallAverageRating;
  final int learningOutcomesAchieved;

  MentorRatingsMetrics({
    required this.topRatedMentors,
    required this.overallAverageRating,
    required this.learningOutcomesAchieved,
  });

  factory MentorRatingsMetrics.fromJson(Map<String, dynamic> json) {
    return MentorRatingsMetrics(
      topRatedMentors:
          (json['topRatedMentors'] as List?)
              ?.map((e) => TopRatedMentor.fromJson(e))
              .toList() ??
          [],
      overallAverageRating: (json['overallAverageRating'] ?? 0).toDouble(),
      learningOutcomesAchieved: json['learningOutcomesAchieved'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topRatedMentors': topRatedMentors.map((e) => e.toJson()).toList(),
      'overallAverageRating': overallAverageRating,
      'learningOutcomesAchieved': learningOutcomesAchieved,
    };
  }
}

class TopRatedMentor {
  final String volunteerId;
  final String volunteerName;
  final double averageRating;
  final int totalRatings;
  final int totalMentees;

  TopRatedMentor({
    required this.volunteerId,
    required this.volunteerName,
    required this.averageRating,
    required this.totalRatings,
    required this.totalMentees,
  });

  factory TopRatedMentor.fromJson(Map<String, dynamic> json) {
    return TopRatedMentor(
      volunteerId: json['volunteerId'] ?? '',
      volunteerName: json['volunteerName'] ?? '',
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      totalMentees: json['totalMentees'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'volunteerId': volunteerId,
      'volunteerName': volunteerName,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'totalMentees': totalMentees,
    };
  }
}

/// Gamification Progress Model
class VolunteerProgress {
  final String volunteerId;
  final String volunteerName;
  final int totalCallsCompleted;
  final int callsGoal;
  final double progressPercentage;
  final List<Milestone> milestones;
  final int nextMilestone;
  final DateTime? estimatedCompletionDate;

  VolunteerProgress({
    required this.volunteerId,
    required this.volunteerName,
    required this.totalCallsCompleted,
    required this.callsGoal,
    required this.progressPercentage,
    required this.milestones,
    required this.nextMilestone,
    this.estimatedCompletionDate,
  });

  factory VolunteerProgress.fromJson(Map<String, dynamic> json) {
    return VolunteerProgress(
      volunteerId: json['volunteerId'] ?? '',
      volunteerName: json['volunteerName'] ?? '',
      totalCallsCompleted: json['totalCallsCompleted'] ?? 0,
      callsGoal: json['callsGoal'] ?? 12,
      progressPercentage: (json['progressPercentage'] ?? 0).toDouble(),
      milestones:
          (json['milestones'] as List?)
              ?.map((e) => Milestone.fromJson(e))
              .toList() ??
          [],
      nextMilestone: json['nextMilestone'] ?? 0,
      estimatedCompletionDate:
          json['estimatedCompletionDate'] != null
              ? DateTime.parse(json['estimatedCompletionDate'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'volunteerId': volunteerId,
      'volunteerName': volunteerName,
      'totalCallsCompleted': totalCallsCompleted,
      'callsGoal': callsGoal,
      'progressPercentage': progressPercentage,
      'milestones': milestones.map((e) => e.toJson()).toList(),
      'nextMilestone': nextMilestone,
      'estimatedCompletionDate': estimatedCompletionDate?.toIso8601String(),
    };
  }
}

class Milestone {
  final int callNumber;
  final bool achieved;
  final DateTime? achievedDate;

  Milestone({
    required this.callNumber,
    required this.achieved,
    this.achievedDate,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      callNumber: json['callNumber'] ?? 0,
      achieved: json['achieved'] ?? false,
      achievedDate:
          json['achievedDate'] != null
              ? DateTime.parse(json['achievedDate'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'callNumber': callNumber,
      'achieved': achieved,
      'achievedDate': achievedDate?.toIso8601String(),
    };
  }
}

/// Enhanced Dashboard Stats Model
class EnhancedDashboardStats {
  final VolunteerStats volunteers;
  final CallStats calls;
  final MoodStats mood;
  final SelfEsteemStats selfEsteem;
  final CallQualityStats callQuality;
  final MentorRatingStats mentorRatings;
  final GamificationStats gamification;

  EnhancedDashboardStats({
    required this.volunteers,
    required this.calls,
    required this.mood,
    required this.selfEsteem,
    required this.callQuality,
    required this.mentorRatings,
    required this.gamification,
  });

  factory EnhancedDashboardStats.fromJson(Map<String, dynamic> json) {
    return EnhancedDashboardStats(
      volunteers: VolunteerStats.fromJson(json['volunteers'] ?? {}),
      calls: CallStats.fromJson(json['calls'] ?? {}),
      mood: MoodStats.fromJson(json['mood'] ?? {}),
      selfEsteem: SelfEsteemStats.fromJson(json['selfEsteem'] ?? {}),
      callQuality: CallQualityStats.fromJson(json['callQuality'] ?? {}),
      mentorRatings: MentorRatingStats.fromJson(json['mentorRatings'] ?? {}),
      gamification: GamificationStats.fromJson(json['gamification'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'volunteers': volunteers.toJson(),
      'calls': calls.toJson(),
      'mood': mood.toJson(),
      'selfEsteem': selfEsteem.toJson(),
      'callQuality': callQuality.toJson(),
      'mentorRatings': mentorRatings.toJson(),
      'gamification': gamification.toJson(),
    };
  }
}

class VolunteerStats {
  final int total;
  final int active;
  final int inMentoring;

  VolunteerStats({
    required this.total,
    required this.active,
    required this.inMentoring,
  });

  factory VolunteerStats.fromJson(Map<String, dynamic> json) {
    return VolunteerStats(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      inMentoring: json['inMentoring'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'total': total, 'active': active, 'inMentoring': inMentoring};
  }
}

class CallStats {
  final int total;
  final double totalHours;
  final double averagePerVolunteer;
  final double frequencyDaily;

  CallStats({
    required this.total,
    required this.totalHours,
    required this.averagePerVolunteer,
    required this.frequencyDaily,
  });

  factory CallStats.fromJson(Map<String, dynamic> json) {
    return CallStats(
      total: json['total'] ?? 0,
      totalHours: (json['totalHours'] ?? 0).toDouble(),
      averagePerVolunteer: (json['averagePerVolunteer'] ?? 0).toDouble(),
      frequencyDaily: (json['frequencyDaily'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'totalHours': totalHours,
      'averagePerVolunteer': averagePerVolunteer,
      'frequencyDaily': frequencyDaily,
    };
  }
}

class MoodStats {
  final double average;
  final String trend;

  MoodStats({required this.average, required this.trend});

  factory MoodStats.fromJson(Map<String, dynamic> json) {
    return MoodStats(
      average: (json['average'] ?? 0).toDouble(),
      trend: json['trend'] ?? 'stable',
    );
  }

  Map<String, dynamic> toJson() {
    return {'average': average, 'trend': trend};
  }
}

class SelfEsteemStats {
  final double average;
  final String trend;

  SelfEsteemStats({required this.average, required this.trend});

  factory SelfEsteemStats.fromJson(Map<String, dynamic> json) {
    return SelfEsteemStats(
      average: (json['average'] ?? 0).toDouble(),
      trend: json['trend'] ?? 'stable',
    );
  }

  Map<String, dynamic> toJson() {
    return {'average': average, 'trend': trend};
  }
}

class CallQualityStats {
  final double average;
  final int totalRated;

  CallQualityStats({required this.average, required this.totalRated});

  factory CallQualityStats.fromJson(Map<String, dynamic> json) {
    return CallQualityStats(
      average: (json['average'] ?? 0).toDouble(),
      totalRated: json['totalRated'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'average': average, 'totalRated': totalRated};
  }
}

class MentorRatingStats {
  final double average;
  final int totalRated;

  MentorRatingStats({required this.average, required this.totalRated});

  factory MentorRatingStats.fromJson(Map<String, dynamic> json) {
    return MentorRatingStats(
      average: (json['average'] ?? 0).toDouble(),
      totalRated: json['totalRated'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'average': average, 'totalRated': totalRated};
  }
}

class GamificationStats {
  final int volunteersCompleted12Calls;
  final double averageProgress;

  GamificationStats({
    required this.volunteersCompleted12Calls,
    required this.averageProgress,
  });

  factory GamificationStats.fromJson(Map<String, dynamic> json) {
    return GamificationStats(
      volunteersCompleted12Calls: json['volunteersCompleted12Calls'] ?? 0,
      averageProgress: (json['averageProgress'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'volunteersCompleted12Calls': volunteersCompleted12Calls,
      'averageProgress': averageProgress,
    };
  }
}
