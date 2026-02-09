import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing user documents in Firestore
class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Valid roles that can be assigned
  static const List<String> validRoles = ['buyer', 'seller'];

  /// Validates if a role is allowed
  static bool isValidRole(String role) {
    return validRoles.contains(role.toLowerCase());
  }

  /// Creates a new user document in Firestore
  /// Throws an exception if the operation fails
  static Future<void> createUser({
    required String uid,
    required String email,
    required String name,
    required String role,
  }) async {
    // Validate role before storing
    if (!isValidRole(role)) {
      throw Exception('Invalid role specified');
    }

    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'role': role.toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
    } catch (e) {
      print('DEBUG: Firestore createUser failed: ${e.runtimeType}');
      // Throw generic message without exposing internal details
      throw Exception('Failed to create user profile');
    }
  }

  /// Retrieves a user document from Firestore
  static Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Connection timeout'),
          );
      return doc.data();
    } catch (e) {
      print('DEBUG: Firestore getUser failed: ${e.runtimeType}');
      // Throw generic message without exposing internal details
      throw Exception('Failed to retrieve user profile');
    }
  }
}
