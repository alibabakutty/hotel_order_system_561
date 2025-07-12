import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_order_system/authentication/auth_models.dart';

class AuthRepository {
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<AuthModels> getAuthModel(String uid) async {
    // First check if user is admin
    final adminDoc = await _firestore.collection('admins').doc(uid).get();
    if (adminDoc.exists) {
      final data = adminDoc.data()!;
      return AuthModels(
        uid: uid,
        username: data['username'] as String?,
        email: data['email'] as String?,
        isAdmin: data['is_admin'] as bool,
        isSupplier: false,
      );
    }

    // Then check if user is supplier
    final supplierDoc = await _firestore.collection('suppliers').doc(uid).get();
    if (supplierDoc.exists) {
      final data = supplierDoc.data()!;
      return AuthModels(
        uid: uid,
        username: data['name'] as String?,
        email: data['email'] as String?,
        mobileNumber: data['mobile_number'] as String?,
        isAdmin: false,
        isSupplier: true,
        supplierId: data['supplier_id'] as String?,
      );
    }

    throw Exception(
      'User document not found in either admins or suppliers collection',
    );
  }

  Future<void> createAdminRecord({
    required String uid,
    required String username,
    required String email,
  }) async {
    await _firestore.collection('admins').doc(uid).set({
      'username': username,
      'email': email,
      'is_admin': true,
      'created_at': FieldValue.serverTimestamp(),
      'last_login': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createSupplierRecord({
    required String uid,
    required String name,
    required String email,
    required String mobileNumber,
    String? supplierId,
  }) async {
    await _firestore.collection('suppliers').doc(uid).set({
      'name': name,
      'email': email,
      'mobile_number': mobileNumber,
      'supplier_id': supplierId ?? uid,
      'is_supplier': true,
      'created_at': FieldValue.serverTimestamp(),
      'last_login': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteUserRecord(String uid) async {
    // Try deleting from both collections
    await Future.wait([
      _firestore.collection('admins').doc(uid).delete(),
      _firestore.collection('suppliers').doc(uid).delete(),
    ]);
  }
}
