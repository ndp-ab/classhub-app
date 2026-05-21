class ClassEvent {
  final int id;
  final String title;
  final String? description;
  final String? location;
  final DateTime? eventTime;
  final String? createdByName;
  final int volunteerCount;
  final int checkedInCount;
  final DateTime? createdAt;

  ClassEvent({
    required this.id,
    required this.title,
    this.description,
    this.location,
    this.eventTime,
    this.createdByName,
    this.volunteerCount = 0,
    this.checkedInCount = 0,
    this.createdAt,
  });

  factory ClassEvent.fromJson(Map<String, dynamic> json) {
    return ClassEvent(
      id: (json['id'] as num).toInt(),
      title: json['title'] ?? '',
      description: json['description'],
      location: json['location'],
      eventTime: json['eventTime'] != null ? DateTime.tryParse(json['eventTime']) : null,
      createdByName: json['createdByName'],
      volunteerCount: (json['volunteerCount'] as num?)?.toInt() ?? 0,
      checkedInCount: (json['checkedInCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}

class EventParticipant {
  final int id;
  final int? eventId;            // B4 bonus: BE giờ trả eventId → bỏ workaround match title
  final int? userId;
  final String? fullName;
  final String? eventTitle;
  final bool checkedIn;
  final DateTime? checkedInAt;
  final String? checkedByName;   // B4: ai check-in
  final DateTime? registeredAt;

  EventParticipant({
    required this.id,
    this.eventId,
    this.userId,
    this.fullName,
    this.eventTitle,
    this.checkedIn = false,
    this.checkedInAt,
    this.checkedByName,
    this.registeredAt,
  });

  factory EventParticipant.fromJson(Map<String, dynamic> json) {
    return EventParticipant(
      id: (json['id'] as num).toInt(),
      eventId: (json['eventId'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      fullName: json['fullName'],
      eventTitle: json['eventTitle'],
      checkedIn: json['checkedIn'] ?? false,
      checkedInAt: json['checkedInAt'] != null ? DateTime.tryParse(json['checkedInAt']) : null,
      checkedByName: json['checkedByName'],
      registeredAt: json['registeredAt'] != null ? DateTime.tryParse(json['registeredAt']) : null,
    );
  }
}
