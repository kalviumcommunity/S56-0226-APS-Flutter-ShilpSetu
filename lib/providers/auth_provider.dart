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
      } else {
        // Document doesn't exist, clear cache
        _userModel = null;
      }
      notifyListeners();
    } catch (e) {
      // Create a basic model from Auth user if Firestore fails (graceful degradation)
      if (_auth.currentUser != null) {
        _userModel = UserModel(
          uid: _auth.currentUser!.uid,
          email: _auth.currentUser!.email ?? '',
          name: 'User', // Fallback
          role: 'buyer', // Default to buyer for safety
          createdAt: DateTime.now(),
        );
        notifyListeners();
      }
      debugPrint('Error fetching user data');
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
      
      // Validate role before proceeding
      if (!UserService.isValidRole(role)) {
        throw Exception('Invalid role selected');
      }
      
      AuditLogger.logSignupAttempt(email);

      // 1. Create Authentication User
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      user = credential.user;

      if (user != null) {
        // 2. Create Firestore User Document
        try {
          await UserService.createUser(
            uid: user.uid,
            email: email.trim(),
            name: name.trim(),
            role: role,
          );
          AuditLogger.logFirestoreUserCreation(user.uid, role);
          
          // Set local user model immediately to avoid another fetch
          _userModel = UserModel(
            uid: user.uid,
            email: email.trim(),
            name: name.trim(),
            role: role,
            createdAt: DateTime.now(),
          );
          notifyListeners();
        } catch (e) {
          // 3. Rollback: Delete Auth User if Firestore fails
          try {
            await user.delete();
            AuditLogger.logFirestoreUserCreationFailure(user.uid, 'rollback_success');
          } catch (deleteError) {
            // Log delete failure but still throw original error
            AuditLogger.logFirestoreUserCreationFailure(user.uid, 'rollback_failed');
          }
          throw Exception('Failed to create user profile. Please try again.');
        }
      }

      AuditLogger.logSignupSuccess(email);
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
      
      // Clear cached user model on logout
      _userModel = null;
      notifyListeners();
    } catch (e) {
      AuditLogger.logLogoutFailure('logout_error');
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
