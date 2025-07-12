import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_order_system/authentication/auth_exception.dart';
import 'package:food_order_system/authentication/auth_models.dart';
import 'package:food_order_system/authentication/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  AuthUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  // Getters
  AuthUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isSupplier => _currentUser?.isSupplier ?? false;

  // Initialize auth state
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _authService.authStateChanges.listen((User? firebaseUser) async {
        if (firebaseUser != null) {
          _currentUser = await _authService.getCurrentAuthUser();
        } else {
          _currentUser = null;
        }
        _error = null;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Authentication methods
  Future<void> _handleAuthOperation(Future<AuthUser> Function() operation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await operation();
      _error = null;
    } on AuthException catch (e) {
      _error = e.message;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> adminSignIn({required String email, required String password}) {
    return _handleAuthOperation(
      () => _authService.adminSignIn(email: email, password: password),
    );
  }

  Future<void> supplierSignIn({required String email, required String password}) {
    return _handleAuthOperation(
      () => _authService.supplierSignIn(email: email, password: password),
    );
  }

  Future<void> createAdminAccount({
    required String username,
    required String email,
    required String password,
  }) {
    return _handleAuthOperation(
      () => _authService.createAdminAccount(
        username: username,
        email: email,
        password: password,
      ),
    );
  }

  Future<void> createSupplierAccount({
    required String name,
    required String email,
    required String password,
    required String mobileNumber,
    String? supplierId,
  }) {
    return _handleAuthOperation(
      () => _authService.createSupplierAccount(
        name: name,
        email: email,
        password: password,
        mobileNumber: mobileNumber,
        supplierId: supplierId,
      ),
    );
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> deleteAccount({required String currentPassword}) async {
    await _handleAuthOperation(
      () async {
        await _authService.deleteAccount(currentPassword: currentPassword);
        return Future.error('User deleted'); // Won't actually return
      },
    );
    _currentUser = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}