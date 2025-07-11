class AuthModels {
  final String uid;
  final String? username;
  final String? email;
  final String? mobileNumber;
  final bool isAdmin;

  AuthModels({
    required this.uid,
    this.username,
    this.email,
    this.mobileNumber,
    this.isAdmin = false,
  });
}
