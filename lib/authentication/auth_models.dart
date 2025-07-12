class AuthUser {
  final String uid;
  final String? username;
  final String? email;
  final String? mobileNumber;
  final UserRole role;
  final String? supplierId;

  AuthUser({
    required this.uid,
    this.username,
    this.email,
    this.mobileNumber,
    this.role = UserRole.user,
    this.supplierId,
  });

  factory AuthUser.fromAdmin(Map<String, dynamic> data, String uid) {
    return AuthUser(
      uid: uid,
      username: data['username'],
      email: data['email'],
      role: UserRole.admin,
    );
  }

  factory AuthUser.fromSupplier(Map<String, dynamic> data, String uid) {
    return AuthUser(
      uid: uid,
      username: data['name'],
      email: data['email'],
      mobileNumber: data['mobile_number'],
      role: UserRole.supplier,
      supplierId: data['supplier_id'] ?? uid,
    );
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isSupplier => role == UserRole.supplier;
  bool get isRegularUser => role == UserRole.user;
}

enum UserRole { user, admin, supplier }