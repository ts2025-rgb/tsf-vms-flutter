/// Model for handover details during the exit process
class HandoverDetails {
  final String? childName;
  final String? childCurrentStatus;
  final String? handoverNotes;
  final DateTime? handoverDate;

  HandoverDetails({
    this.childName,
    this.childCurrentStatus,
    this.handoverNotes,
    this.handoverDate,
  });

  factory HandoverDetails.fromJson(Map<String, dynamic>? json) {
    if (json == null) return HandoverDetails();
    
    return HandoverDetails(
      childName: json['childName'] as String?,
      childCurrentStatus: json['childCurrentStatus'] as String?,
      handoverNotes: json['handoverNotes'] as String?,
      handoverDate: json['handoverDate'] != null 
          ? DateTime.tryParse(json['handoverDate'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (childName != null) 'childName': childName,
      if (childCurrentStatus != null) 'childCurrentStatus': childCurrentStatus,
      if (handoverNotes != null) 'handoverNotes': handoverNotes,
      if (handoverDate != null) 'handoverDate': handoverDate!.toIso8601String(),
    };
  }

  bool get isComplete => childName != null && childName!.isNotEmpty;

  HandoverDetails copyWith({
    String? childName,
    String? childCurrentStatus,
    String? handoverNotes,
    DateTime? handoverDate,
  }) {
    return HandoverDetails(
      childName: childName ?? this.childName,
      childCurrentStatus: childCurrentStatus ?? this.childCurrentStatus,
      handoverNotes: handoverNotes ?? this.handoverNotes,
      handoverDate: handoverDate ?? this.handoverDate,
    );
  }

  @override
  String toString() {
    return 'HandoverDetails(childName: $childName, childCurrentStatus: $childCurrentStatus, handoverNotes: $handoverNotes, handoverDate: $handoverDate)';
  }
}
