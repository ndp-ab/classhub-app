class AppNotification {
  final int recipientId;
  final int notificationId;
  final int? classroomId;
  final String type;
  final String title;
  final String message;
  final String? targetType;
  final int? targetId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final String? createdByName;

  AppNotification({
    required this.recipientId,
    required this.notificationId,
    this.classroomId,
    required this.type,
    required this.title,
    required this.message,
    this.targetType,
    this.targetId,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    this.createdByName,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      recipientId: _readInt(json['recipientId']),
      notificationId: _readInt(json['notificationId']),
      classroomId: _readNullableInt(json['classroomId']),
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      targetType: json['targetType']?.toString(),
      targetId: _readNullableInt(json['targetId']),
      isRead: _readBool(json['isRead'] ?? json['read']),
      readAt: _readNullableDate(json['readAt']),
      createdAt:
          _readNullableDate(json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      createdByName: json['createdByName']?.toString(),
    );
  }

  AppNotification copyWith({bool? isRead, DateTime? readAt}) {
    return AppNotification(
      recipientId: recipientId,
      notificationId: notificationId,
      classroomId: classroomId,
      type: type,
      title: title,
      message: message,
      targetType: targetType,
      targetId: targetId,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      createdByName: createdByName,
    );
  }
}

int _readInt(dynamic value) {
  return _readNullableInt(value) ?? 0;
}

int? _readNullableInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool _readBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true';
  return false;
}

DateTime? _readNullableDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
