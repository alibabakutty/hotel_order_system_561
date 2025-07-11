import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_order_system/authentication/auth_exception.dart';
import 'package:food_order_system/authentication/auth_models.dart';
import 'package:food_order_system/authentication/auth_repository.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final AuthRepository _authRepository;

  AuthService({FirebaseAuth? firebaseAuth, AuthRepository? authRepository})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _authRepository = authRepository ?? AuthRepository();

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<AuthModels> getAuthModels(String uid) async {
    return await _authRepository.getAuthModel(uid);
  }

  Future<User> signIn({required String email, required String password}) async {
    try {
      email = email.trim();
      password = password.trim();

      if (email.isEmpty || password.isEmpty) {
        throw AuthException(
          code: 'Invalid email-or-password',
          message: "Email and password cannot be empty",
        );
      }

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw AuthException(
          code: 'no-user',
          message: 'Authentication succeeded but no user returned',
        );
      }

      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        code: e.code,
        message: AuthErrorMessages.getMessage(e.code),
      );
    } catch (e) {
      throw AuthException(
        code: 'unknown-error',
        message: 'Unknown error occured',
      );
    }
  }

  Future<User?> createNewAccount({
    required String username,
    required String email,
    required String password,
    required bool isAdmin,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;

      await _authRepository.createUserRecord(
        uid: user.uid,
        username: username,
        email: email,
        isAdmin: isAdmin,
      );

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        code: e.code,
        message: AuthErrorMessages.getMessage(e.code),
      );
    } catch (e) {
      throw AuthException(
        code: 'account-creation-failed',
        message: 'Failed to create account: ${e.toString()}',
      );
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> deleteAccount({required String currentPassword}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw AuthException(
        code: 'no-user',
        message: 'No User is currently signed in',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    try {
      await user.reauthenticateWithCredential(credential);
      await _authRepository.deleteUserRecord(user.uid);
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        code: e.code,
        message: AuthErrorMessages.getMessage(e.code),
      );
    }
  }
}
