import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

/// User model representing a user in the system
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // "buyer" or "seller"
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
  });

  /// Convert UserModel to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Handle serverTimestamp which can be null on first read
    DateTime createdAt;
    final createdAtField = map['createdAt'];
    
    if (createdAtField == null) {
      // Use current time if serverTimestamp hasn't resolved yet
      createdAt = DateTime.now();
    } else if (createdAtField is Timestamp) {
      createdAt = createdAtField.toDate();
    } else {
      // Fallback for unexpected types
      createdAt = DateTime.now();
    }

    return UserModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? 'User',
      role: map['role'] as String? ?? 'buyer',
      createdAt: createdAt,
    );
  }

  /// Create UserModel from Firebase Auth user
  factory UserModel.fromFirebaseUser({
    required auth.User user,
    required String name,
    required String role,
  }) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      name: name,
      role: role,
      createdAt: DateTime.now(),
    );
  }
}
