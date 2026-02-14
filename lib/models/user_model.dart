import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

/// User model representing a user in the system
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // "buyer", "seller", or "admin"
  final DateTime createdAt;
  final bool isActive; // NEW: User account status
  
  // Seller-specific fields (optional for buyers)
  final String? bio;
  final String? profileImageUrl;
  final String? city;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    this.isActive = true, // Default to active
    this.bio,
    this.profileImageUrl,
    this.city,
  });

  /// Convert UserModel to Firestore-compatible map
  /// Note: uid is NOT stored in document, only used as document ID
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      if (bio != null) 'bio': bio,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (city != null) 'city': city,
    };
  }

  /// Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
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
      uid: uid, // uid comes from document ID, not from map
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? 'User',
      role: map['role'] as String? ?? 'buyer',
      createdAt: createdAt,
      isActive: map['isActive'] as bool? ?? true,
      bio: map['bio'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
      city: map['city'] as String?,
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

  /// Helper to check if user is a seller
  bool get isSeller => role == 'seller';

  /// Helper to check if user is a buyer
  bool get isBuyer => role == 'buyer';
  
  /// Helper to check if user is an admin
  bool get isAdmin => role == 'admin';
}
