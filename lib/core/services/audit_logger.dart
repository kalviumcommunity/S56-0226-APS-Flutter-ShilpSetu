import 'dart:developer' as developer;

/// Audit logging service for authentication events
class AuditLogger {
  static const String _source = 'AuthAudit';

  /// Logs a login attempt
  static void logLoginAttempt(String email) {
    developer.log(
      'Login attempt',
      time: DateTime.now(),
      name: _source,
      error: {'email': email},
    );
  }

  /// Logs a successful login
  static void logLoginSuccess(String email) {
    developer.log(
      'Login successful',
      time: DateTime.now(),
      name: _source,
      error: {'email': email},
    );
  }

  /// Logs a failed login with error code
  static void logLoginFailure(String email, String errorCode) {
    developer.log(
      'Login failed',
      time: DateTime.now(),
      name: _source,
      error: {'email': email, 'errorCode': errorCode},
    );
  }

  /// Logs a signup attempt
  static void logSignupAttempt(String email) {
    developer.log(
      'Signup attempt',
      time: DateTime.now(),
      name: _source,
      error: {'email': email},
    );
  }

  /// Logs a successful signup
  static void logSignupSuccess(String email) {
    developer.log(
      'Signup successful',
      time: DateTime.now(),
      name: _source,
      error: {'email': email},
    );
  }

  /// Logs a failed signup with error code
  static void logSignupFailure(String email, String errorCode) {
    developer.log(
      'Signup failed',
      time: DateTime.now(),
      name: _source,
      error: {'email': email, 'errorCode': errorCode},
    );
  }

  /// Logs a logout event
  static void logLogout(String? email) {
    developer.log(
      'Logout',
      time: DateTime.now(),
      name: _source,
      error: {'email': email ?? 'unknown'},
    );
  }

  /// Logs a logout failure
  static void logLogoutFailure(String error) {
    developer.log(
      'Logout failed',
      time: DateTime.now(),
      name: _source,
      error: {'error': error},
    );
  }
}
