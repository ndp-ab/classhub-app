class ClassMember {
  final int userId;
  final String fullName;
  final String email;
  final String role;
  final DateTime? joinedAt;

  ClassMember({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.joinedAt,
  });

  factory ClassMember.fromJson(Map<String, dynamic> json) {
    return ClassMember(
      userId: (json['userId'] as num).toInt(),
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'])
          : null,
    );
  }
}
