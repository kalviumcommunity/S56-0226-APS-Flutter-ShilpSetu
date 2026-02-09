import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/services/audit_logger.dart';
import '../core/services/user_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _loading = false;
  bool get loading => _loading;

  User? get currentUser => _auth.currentUser;

  // Cache user data to avoid frequent Firestore fetches
  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  /// Fetches user data from Firestore and updates state
  Future<void> fetchUserData(String uid) async {
    try {
      final userData = await UserService.getUser(uid);
      if (userData != null) {
        _userModel = UserModel.fromMap(userData);
        notifyListeners();
      }
    } catch (e) {
      // Create a basic model from Auth user if Firestore fails (graceful degradation)
      if (_auth.currentUser != null) {
        _userModel = UserModel(
          uid: _auth.currentUser!.uid,
          email: _auth.currentUser!.email ?? '',
          name: 'User', // Fallback
          role: 'unknown',
          createdAt: DateTime.now(),
        );
      }
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      _setLoading(true);
      AuditLogger.logLoginAttempt(email);

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      AuditLogger.logLoginSuccess(email);
      if (credential.user != null) {
        await fetchUserData(credential.user!.uid);
      }
      return credential.user;
    } on FirebaseAuthException catch (e) {
      AuditLogger.logLoginFailure(email, e.code);
      // Return a generic error code, not the detailed message
      throw FirebaseAuthException(
        code: e.code,
        message: _getGenericErrorMessage(e.code),
      );
    } catch (e) {
      AuditLogger.logLoginFailure(email, 'unknown_error');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<User?> signup({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    User? user;
    try {
      _setLoading(true);
      AuditLogger.logSignupAttempt(email);

      // 1. Create Authentication User
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      user = credential.user;
      print('DEBUG: Auth user created: ${user?.uid}');

      if (user != null) {
        // 2. Create Firestore User Document
        try {
          print('DEBUG: Creating Firestore document...');
          await UserService.createUser(
            uid: user.uid,
            email: email.trim(),
            name: name.trim(),
            role: role,
          );
          print('DEBUG: Firestore document created successfully');
          AuditLogger.logFirestoreUserCreation(user.uid, role);
          
          // Set local user model immediately to avoid another fetch
          _userModel = UserModel(
            uid: user.uid,
            email: email.trim(),
            name: name.trim(),
            role: role,
            createdAt: DateTime.now(),
          );
          print('DEBUG: Local user model set');
          notifyListeners();
          print('DEBUG: Listeners notified');
        } catch (e) {
          print('DEBUG: Firestore creation failed: $e');
          // 3. Rollback: Delete Auth User if Firestore fails
          await user.delete();
          AuditLogger.logFirestoreUserCreationFailure(user.uid, e.toString());
          throw Exception('Failed to create user profile. Please try again.');
        }
      }

      AuditLogger.logSignupSuccess(email);
      print('DEBUG: Signup success, returning user');
      return user;
    } on FirebaseAuthException catch (e) {
      AuditLogger.logSignupFailure(email, e.code);
      throw FirebaseAuthException(
        code: e.code,
        message: _getGenericErrorMessage(e.code),
      );
    } catch (e) {
      AuditLogger.logSignupFailure(email, 'unknown_error');
      // If it's our custom rollback exception, rethrow it
      if (e.toString().contains('Failed to create user profile')) {
        rethrow;
      }
      throw Exception('An error occurred. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      final email = _auth.currentUser?.email;
      AuditLogger.logLogout(email);
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      AuditLogger.logLogoutFailure(e.toString());
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  /// Returns a generic error message based on Firebase error code
  /// This prevents exposing sensitive error details to users
  static String _getGenericErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid email or password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This operation is not allowed';
      case 'email-already-in-use':
        return 'An account with this email already exists';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'The password is too weak';
      default:
        return 'An error occurred. Please try again';
    }
  }
}
