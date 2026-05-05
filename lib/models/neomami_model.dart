/// Model for Neomami Hub Entry
class NeomamEntry {
  final String? id;
  final String volunteerId;
  final String title;
  final String description;
  final int hoursDedicated;
  final String skillsLearned;
  final String? linkOfWork;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NeomamEntry({
    this.id,
    required this.volunteerId,
    required this.title,
    required this.description,
    required this.hoursDedicated,
    required this.skillsLearned,
    this.linkOfWork,
    this.createdAt,
    this.updatedAt,
  });

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'contentPostedTitle': title,
      'contentPostedDescription': description,
      'hoursDedicated': hoursDedicated,
      'newSkillsLearned': skillsLearned,
      if (linkOfWork != null && linkOfWork!.isNotEmpty)
        'linkOfWork': linkOfWork,
    };
  }

  /// Create from JSON response
  factory NeomamEntry.fromJson(Map<String, dynamic> json) {
    return NeomamEntry(
      id: json['_id'] ?? json['id'],
      volunteerId: json['volunteerId'] ?? '',
      title: json['contentPostedTitle'] ?? json['title'] ?? '',
      description:
          json['contentPostedDescription'] ?? json['description'] ?? '',
      hoursDedicated: int.tryParse(json['hoursDedicated'].toString()) ?? 0,
      skillsLearned: json['newSkillsLearned'] ?? json['skillsLearned'] ?? '',
      linkOfWork: json['linkOfWork'],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'].toString())
              : null,
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'].toString())
              : null,
    );
  }

  /// Create a copy with updated fields
  NeomamEntry copyWith({
    String? id,
    String? volunteerId,
    String? title,
    String? description,
    int? hoursDedicated,
    String? skillsLearned,
    String? linkOfWork,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NeomamEntry(
      id: id ?? this.id,
      volunteerId: volunteerId ?? this.volunteerId,
      title: title ?? this.title,
      description: description ?? this.description,
      hoursDedicated: hoursDedicated ?? this.hoursDedicated,
      skillsLearned: skillsLearned ?? this.skillsLearned,
      linkOfWork: linkOfWork ?? this.linkOfWork,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Response model for Neomami Hub API
class NeomamResponse {
  final bool success;
  final String message;
  final dynamic data;

  NeomamResponse({required this.success, required this.message, this.data});

  factory NeomamResponse.fromJson(Map<String, dynamic> json) {
    return NeomamResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}
