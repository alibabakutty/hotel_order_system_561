import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_order_system/authentication/auth_models.dart';
import 'package:food_order_system/authentication/auth_repository.dart';
import 'package:food_order_system/authentication/auth_exception.dart';

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
    if (user == null) throw AuthException(code: 'no-user', message: AuthErrorMessages.getMessage('no-user'));
    return _authRepository.getAuthUser(user.uid);
  }

  Future<AuthUser> _signInWithRole({
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
          message: AuthErrorMessages.getMessage('empty-credentials'),
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
          message: AuthErrorMessages.getMessage('no-user'),
        );
      }

      final authUser = await _authRepository.getAuthUser(user.uid);
      if (authUser.role != expectedRole) {
        await _firebaseAuth.signOut();
        throw AuthException(
          code: 'wrong-role',
          message: AuthErrorMessages.getMessage('wrong-role'),
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
  }) async => _signInWithRole(
        email: email,
        password: password,
        expectedRole: UserRole.admin,
      );

  Future<AuthUser> supplierSignIn({
    required String email,
    required String password,
  }) async => _signInWithRole(
        email: email,
        password: password,
        expectedRole: UserRole.supplier,
      );

  Future<AuthUser> _createUserWithRole(SignUpCredentials credentials, Map<String, dynamic> additionalData) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: credentials.email,
        password: credentials.password,
      );

      final user = userCredential.user!;
      
      await _authRepository.createUserRecord(
        uid: user.uid,
        data: {
          'email': credentials.email,
          ...additionalData,
        },
        role: credentials.role,
      );

      return AuthUser.fromMap(
        additionalData,
        user.uid,
        credentials.role,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        code: e.code,
        message: AuthErrorMessages.getMessage(e.code),
      );
    }
  }

  Future<AuthUser> createAdminAccount(AdminSignUpData data) async =>
      await _createUserWithRole(
        data,
        {'username': data.username},
      );

  Future<AuthUser> createSupplierAccount(SupplierSignUpData data) async =>
      await _createUserWithRole(
        data,
        {
          'name': data.name,
          'mobileNumber': data.mobileNumber,
        },
      );

  Future<void> signOut() async => await _firebaseAuth.signOut();

  Future<void> deleteAccount({required String currentPassword}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw AuthException(code: 'no-user', message: AuthErrorMessages.getMessage('no-user'));

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