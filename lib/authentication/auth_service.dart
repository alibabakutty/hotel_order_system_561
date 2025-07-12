import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_order_system/authentication/auth_exception.dart';
import 'package:food_order_system/authentication/auth_models.dart';
import 'package:food_order_system/authentication/auth_repository.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final AuthRepository _authRepository;

  AuthService({
    FirebaseAuth? firebaseAuth,
    AuthRepository? authRepository,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _authRepository = authRepository ?? AuthRepository();

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<AuthUser> getCurrentAuthUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw AuthException(
        code: 'no-user',
        message: 'No user is currently signed in',
      );
    }
    return _authRepository.getAuthUser(user.uid);
  }

  Future<AuthUser> _signInWithEmailAndPassword({
    required String email,
    required String password,
    required UserRole expectedRole,
  }) async {
    try {
      email = email.trim();
      password = password.trim();

      if (email.isEmpty || password.isEmpty) {
        throw AuthException(
          code: 'empty-credentials',
          message: 'Email and password cannot be empty',
        );
      }

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw AuthException(
          code: 'no-user',
          message: 'Authentication succeeded but no user returned',
        );
      }

      final authUser = await _authRepository.getAuthUser(user.uid);
      
      if (authUser.role != expectedRole) {
        await _firebaseAuth.signOut();
        throw AuthException(
          code: 'wrong-role',
          message: 'This account does not have the required permissions',
        );
      }

      return authUser;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        code: e.code,
        message: AuthErrorMessages.getMessage(e.code),
      );
    }
  }

  Future<AuthUser> adminSignIn({
    required String email,
    required String password,
  }) async {
    return _signInWithEmailAndPassword(
      email: email,
      password: password,
      expectedRole: UserRole.admin,
    );
  }

  Future<AuthUser> supplierSignIn({
    required String email,
    required String password,
  }) async {
    return _signInWithEmailAndPassword(
      email: email,
      password: password,
      expectedRole: UserRole.supplier,
    );
  }

  Future<AuthUser> createAdminAccount({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;
      
      await _authRepository.createAdminRecord(
        uid: user.uid,
        username: username,
        email: email,
      );

      return AuthUser.fromAdmin(
        {
          'username': username,
          'email': email,
        },
        user.uid,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        code: e.code,
        message: AuthErrorMessages.getMessage(e.code),
      );
    }
  }

  Future<AuthUser> createSupplierAccount({
    required String name,
    required String email,
    required String password,
    required String mobileNumber,
    String? supplierId,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;
      
      await _authRepository.createSupplierRecord(
        uid: user.uid,
        name: name,
        email: email,
        mobileNumber: mobileNumber,
        supplierId: supplierId,
      );

      return AuthUser.fromSupplier(
        {
          'name': name,
          'email': email,
          'mobile_number': mobileNumber,
          'supplier_id': supplierId ?? user.uid,
        },
        user.uid,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        code: e.code,
        message: AuthErrorMessages.getMessage(e.code),
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
        message: 'No user is currently signed in',
      );
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
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