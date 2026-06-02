class UserRoles {
  const UserRoles._();

  static const String admin = 'ADMIN';
  static const String owner = 'OWNER';
  static const String member = 'MEMBER';

  static bool isAdminLike(String? role) {
    return role == admin || role == owner;
  }

  static bool isMember(String? role) {
    return role == member;
  }
}
