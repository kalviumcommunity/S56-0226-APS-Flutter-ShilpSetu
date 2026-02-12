import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/services/audit_logger.dart';
import '../core/services/user_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

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
        _userModel = UserModel.fromMap(userData, uid);
      } else {
        _userModel = null;
      }
      notifyListeners();
    } catch (e) {
      // Graceful fallback
      if (_auth.currentUser != null) {
        _userModel = UserModel(
          uid: _auth.currentUser!.uid,
          email: _auth.currentUser!.email ?? '',
          name: 'User',
          role: 'buyer',
          createdAt: DateTime.now(),
        );
        notifyListeners();
      }

      if (kDebugMode) {
        debugPrint('Error fetching user data');
      }
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

      if (!UserService.isValidRole(role)) {
        throw Exception('Invalid role selected');
      }

      AuditLogger.logSignupAttempt(email);

      // 1️⃣ Create Auth User
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      user = credential.user;

      if (user != null) {
        try {
          // 2️⃣ Create Firestore User Document
          await UserService.createUser(
            uid: user.uid,
            email: email.trim(),
            name: name.trim(),
            role: role,
          );

          AuditLogger.logFirestoreUserCreation(user.uid, role);

          // 3️⃣ Cache locally
          _userModel = UserModel(
            uid: user.uid,
            email: email.trim(),
            name: name.trim(),
            role: role,
            createdAt: DateTime.now(),
          );

          notifyListeners();
        } catch (e) {
          // 4️⃣ Rollback if Firestore fails
          try {
            await user.delete();
            AuditLogger.logFirestoreUserCreationFailure(
                user.uid, 'rollback_success');
          } catch (_) {
            AuditLogger.logFirestoreUserCreationFailure(
                user.uid, 'rollback_failed');
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

      if (e.toString().contains('Failed to create user profile')) {
        rethrow;
      }

      throw Exception('An error occurred. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> getUserRole(String uid) async {
    try {
      return await _userService.getUserRole(uid);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting user role: $e');
      }
      return null;
    }
  }

  Future<void> logout() async {
    try {
      final email = _auth.currentUser?.email;
      AuditLogger.logLogout(email);

      await _auth.signOut();

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
