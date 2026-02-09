import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing user documents in Firestore
class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a new user document in Firestore
  /// Throws an exception if the operation fails
  static Future<void> createUser({
    required String uid,
    required String email,
    required String name,
    required String role,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
    } catch (e) {
      print('DEBUG: Firestore createUser failed: $e');
      // Rethrow with generic message for security
      throw Exception('Failed to create user profile: $e');
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
      print('DEBUG: Firestore getUser failed: $e'); // Log the real error
      throw Exception('Failed to retrieve user profile: $e');
    }
  }
}
