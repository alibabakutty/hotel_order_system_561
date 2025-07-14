enum UserRole { user, admin, supplier }

class AuthUser {
  final String uid;
  final String? username;
  final String? supplierName;
  final String? email;
  final String? mobileNumber;
  final UserRole role;

  AuthUser({
    required this.uid,
    this.username,
    this.supplierName,
    this.email,
    this.mobileNumber,
    this.role = UserRole.user,
  });

  factory AuthUser.fromMap(
    Map<String, dynamic> data,
    String uid,
    UserRole role,
  ) {
    return AuthUser(
      uid: uid,
      username: data['username'],
      supplierName: data['supplierName'] ?? data['name'],
      email: data['email'],
      mobileNumber: data['mobileNumber'] ?? data['mobile_number'],
      role: role,
    );
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isSupplier => role == UserRole.supplier;
  bool get isRegularUser => role == UserRole.user;
}

class SignUpCredentials {
  final String email;
  final String password;
  final UserRole role;

  SignUpCredentials({
    required this.email,
    required this.password,
    required this.role,
  });
}

class AdminSignUpData extends SignUpCredentials {
  final String username;

  AdminSignUpData({
    required String email,
    required String password,
    required this.username,
  }) : super(email: email, password: password, role: UserRole.admin);
}

class SupplierSignUpData extends SignUpCredentials {
  final String name;
  final String mobileNumber;

  SupplierSignUpData({
    required String email,
    required String password,
    required this.name,
    required this.mobileNumber,
  }) : super(email: email, password: password, role: UserRole.supplier);
}
