import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/firestore_collections.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUserDocument({
    required String uid,
    required String email,
    required String role,
    String? name,
  }) async {
    try {
      await _firestore.collection(FirestoreCollections.users).doc(uid).set({
        'name': name ?? email.split('@')[0], // Use email prefix if name not provided
        'email': email,
        'role': role,
        'createdAt': Timestamp.now(),
      });
      if (kDebugMode) {
        print('✅ User document created: $uid with role: $role');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating user document: $e');
      }
      throw Exception('Failed to create user document: $e');
    }
  }

  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection(FirestoreCollections.users).doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching user role: $e');
      }
      throw Exception('Failed to fetch user role: $e');
    }
  }
}
