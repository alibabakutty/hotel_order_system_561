class AuthModels {
  final String uid; // Changed from adminId to more generic uid
  final String? username;
  final String? email;
  final String? mobileNumber;
  final bool isAdmin;
  final bool isSupplier;
  final String? supplierId; // Specific ID for suppliers if needed

  AuthModels({
    required this.uid,
    this.username,
    this.email,
    this.mobileNumber,
    this.isAdmin = false,
    this.isSupplier = false,
    this.supplierId,
  });

  // Helper method to check user role
  String get role {
    if (isAdmin) return 'admin';
    if (isSupplier) return 'supplier';
    return 'user';
  }
}