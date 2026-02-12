import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/services/audit_logger.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  bool _loading = false;
  bool get loading => _loading;

  User? get currentUser => _auth.currentUser;

  Future<User?> login(String email, String password) async {
    try {
      _setLoading(true);
      AuditLogger.logLoginAttempt(email);

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      AuditLogger.logLoginSuccess(email);
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

  Future<User?> signup(String email, String password, String role) async {
    try {
      _setLoading(true);
      AuditLogger.logSignupAttempt(email);

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Create user document in Firestore with selected role
      if (credential.user != null) {
        await _userService.createUserDocument(
          uid: credential.user!.uid,
          email: email.trim(),
          role: role,
        );
      }

      AuditLogger.logSignupSuccess(email);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      AuditLogger.logSignupFailure(email, e.code);
      // Return a generic error code, not the detailed message
      throw FirebaseAuthException(
        code: e.code,
        message: _getGenericErrorMessage(e.code),
      );
    } catch (e) {
      AuditLogger.logSignupFailure(email, 'unknown_error');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> getUserRole(String uid) async {
    try {
      return await _userService.getUserRole(uid);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting user role: $e');
      }
      return null;
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
