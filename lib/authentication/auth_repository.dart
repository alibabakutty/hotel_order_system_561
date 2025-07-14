import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_order_system/authentication/auth_exception.dart';
import 'package:food_order_system/authentication/auth_models.dart';

class AuthRepository {
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<AuthUser> _getUserFromCollection(
    String collection,
    String uid,
    UserRole role,
  ) async {
    final doc = await _firestore.collection(collection).doc(uid).get();
    if (!doc.exists) return Future.error('User not found in $collection');
    return AuthUser.fromMap(doc.data()!, uid, role);
  }

  Future<AuthUser> getAuthUser(String uid) async {
    try {
      return await _getUserFromCollection('admins', uid, UserRole.admin)
          .onError(
            (_, __) =>
                _getUserFromCollection('suppliers', uid, UserRole.supplier),
          )
          .onError(
            (_, __) => _getUserFromCollection('users', uid, UserRole.user),
          );
    } on FirebaseException catch (e) {
      throw AuthException(
        code: e.code,
        message: 'Failed to fetch user data: ${e.message}',
      );
    }
  }

  Future<void> createUserRecord({
    required String uid,
    required Map<String, dynamic> data,
    required UserRole role,
  }) async {
    try {
      final collection = role == UserRole.admin
          ? 'admins'
          : role == UserRole.supplier
          ? 'suppliers'
          : 'users';

      await _firestore.collection(collection).doc(uid).set({
        ...data,
        'created_at': FieldValue.serverTimestamp(),
        'last_login': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AuthException(
        code: e.code,
        message: 'Failed to create user record: ${e.message}',
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
