import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_order_system/authentication/auth_models.dart';

class AuthRepository {
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<AuthModels> getAuthModel(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw Exception('User document not found');
    }

    final data = doc.data()!;
    return AuthModels(
      uid: uid,
      username: data['username'] as String?,
      email: data['email'] as String?,
      isAdmin: data['is_admin'] as bool,
    );
  }

  Future<void> createUserRecord({
    required String uid,
    required String username,
    required String email,
    required bool isAdmin,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'username': username,
      'email': email,
      'is_admin': isAdmin,
      'created_at': FieldValue.serverTimestamp(),
      'last_login': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteUserRecord(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }
}
