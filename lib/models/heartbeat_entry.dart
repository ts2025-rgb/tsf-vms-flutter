class HeartbeatEntry {
  final String id;
  final int hours;
  final String activityType;
  final String? activityDetail;
  final DateTime createdAt;

  HeartbeatEntry({
    required this.id,
    required this.hours,
    required this.activityType,
    this.activityDetail,
    required this.createdAt,
  });

  factory HeartbeatEntry.fromJson(Map<String, dynamic> json) {
    return HeartbeatEntry(
      id: json['_id'] ?? json['id'] ?? '',
      hours:
          (json['hoursVolunteered'] is int)
              ? json['hoursVolunteered']
              : int.tryParse('${json['hoursVolunteered']}') ?? 0,
      activityType: json['activityType'] ?? json['activity'] ?? '',
      activityDetail: json['activityDetails'] ?? json['activityDetail'] ?? null,
      createdAt:
          DateTime.tryParse(
            json['createdAt'] ?? json['createdAt']?.toString() ?? '',
          ) ??
          DateTime.tryParse(json['createdAt'] ?? '') ??
          DateTime.now(),
    );
  }
}
