import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_collections.dart';

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
  /// Note: uid is NOT stored inside document, only used as document ID
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
      await _firestore.collection(FirestoreCollections.users).doc(uid).set({
        'email': email,
        'name': name,
        'role': role.toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
    } catch (e) {
      // Throw generic message without exposing internal details
      throw Exception('Failed to create user profile');
    }
  }

  /// Retrieves a user document from Firestore
  static Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Connection timeout'),
          );
      return doc.data();
    } catch (e) {
      // Throw generic message without exposing internal details
      throw Exception('Failed to retrieve user profile');
    }
  }

  /// Get user role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      final userData = await UserService.getUser(uid);
      return userData?['role'] as String?;
    } catch (e) {
      return null;
    }
  }
}

