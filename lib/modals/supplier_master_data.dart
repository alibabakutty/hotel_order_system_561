import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierMasterData {
  final String supplierName;
  final String mobileNumber;
  final String email;
  final String password;
  final bool isAdmin;
  final Timestamp createdAt;

  SupplierMasterData({
    required this.supplierName,
    required this.mobileNumber,
    required this.email,
    required this.password,
    this.isAdmin = false,
    required this.createdAt,
  });

  // convert data from firestore to SupplierName Master object
  factory SupplierMasterData.fromfirestore(Map<String, dynamic> data) {
    return SupplierMasterData(
      supplierName: data['supplier_name'] ?? '',
      mobileNumber: data['mobile_number'] ?? '',
      email: data['email'] ?? '',
      password: data['password'] ?? '',
      isAdmin: data['is_admin'] ?? false,
      createdAt: data['created_at'] ?? Timestamp.now(),
    );
  }

  // convert Supplier master data object to firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'supplier_name': supplierName,
      'mobile_number': mobileNumber,
      'email': email,
      'password': password,
      'is_admin': isAdmin,
      'created_at': createdAt,
    };
  }
}
