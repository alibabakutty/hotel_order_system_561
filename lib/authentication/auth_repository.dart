import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_order_system/authentication/auth_exception.dart';
import 'package:food_order_system/authentication/auth_models.dart';

class AuthRepository {
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<AuthUser> getAuthUser(String uid) async {
    try {
      // Check admin collection first
      final adminDoc = await _firestore.collection('admins').doc(uid).get();
      if (adminDoc.exists) {
        return AuthUser.fromAdmin(adminDoc.data()!, uid);
      }

      // Check supplier collection
      final supplierDoc = await _firestore.collection('suppliers').doc(uid).get();
      if (supplierDoc.exists) {
        return AuthUser.fromSupplier(supplierDoc.data()!, uid);
      }

      // If not found in either, return basic user
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return AuthUser(
          uid: uid,
          email: userDoc.data()?['email'],
          role: UserRole.user,
        );
      }

      throw AuthException(
        code: 'user-not-found',
        message: 'User document not found in any collection',
      );
    } on FirebaseException catch (e) {
      throw AuthException(
        code: e.code,
        message: 'Failed to fetch user data: ${e.message}',
      );
    }
  }

  Future<void> createAdminRecord({
    required String uid,
    required String username,
    required String email,
  }) async {
    try {
      await _firestore.collection('admins').doc(uid).set({
        'username': username,
        'email': email,
        'created_at': FieldValue.serverTimestamp(),
        'last_login': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AuthException(
        code: e.code,
        message: 'Failed to create admin record: ${e.message}',
      );
    }
  }

  Future<void> createSupplierRecord({
    required String uid,
    required String name,
    required String email,
    required String mobileNumber,
    String? supplierId,
  }) async {
    try {
      await _firestore.collection('suppliers').doc(uid).set({
        'name': name,
        'email': email,
        'mobile_number': mobileNumber,
        'supplier_id': supplierId ?? uid,
        'created_at': FieldValue.serverTimestamp(),
        'last_login': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AuthException(
        code: e.code,
        message: 'Failed to create supplier record: ${e.message}',
      );
    }
  }

  Future<void> deleteUserRecord(String uid) async {
    try {
      await Future.wait([
        _firestore.collection('admins').doc(uid).delete(),
        _firestore.collection('suppliers').doc(uid).delete(),
        _firestore.collection('users').doc(uid).delete(),
      ]);
    } on FirebaseException catch (e) {
      throw AuthException(
        code: e.code,
        message: 'Failed to delete user records: ${e.message}',
      );
    }
  }
}