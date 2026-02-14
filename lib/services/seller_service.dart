import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../models/seller_stats.dart';
import '../models/product_model.dart';
import '../core/constants/firestore_collections.dart';
import 'cloudinary_service.dart';

class SellerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  /// Gets seller profile by ID
  Future<UserModel?> getSellerProfile(String sellerId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(sellerId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching seller profile: $e');
      }
      rethrow;
    }
  }

  /// Gets aggregated statistics for a seller
  /// Calculates weighted average rating across all products
  Future<SellerStats> getSellerStats(String sellerId) async {
    try {
      // Fetch all products by seller
      final productsSnapshot = await _firestore
          .collection(FirestoreCollections.products)
          .where('sellerId', isEqualTo: sellerId)
          .get();

      if (productsSnapshot.docs.isEmpty) {
        return SellerStats.empty();
      }

      final products = productsSnapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();

      // Calculate statistics
      int totalReviewCount = 0;
      double weightedRatingSum = 0.0;
      int activeProducts = 0;

      for (final product in products) {
        if (product.isActive) {
          activeProducts++;
        }

        if (product.reviewCount > 0) {
          totalReviewCount += product.reviewCount;
          weightedRatingSum += product.averageRating * product.reviewCount;
        }
      }

      // Calculate overall rating (weighted average)
      final overallRating = totalReviewCount > 0
          ? weightedRatingSum / totalReviewCount
          : 0.0;

      return SellerStats(
        overallRating: overallRating,
        totalReviewCount: totalReviewCount,
        totalProducts: products.length,
        activeProducts: activeProducts,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching seller stats: $e');
      }
      return SellerStats.empty();
    }
  }

  /// Updates seller profile information
  Future<void> updateSellerProfile({
    required String sellerId,
    String? bio,
    String? city,
    XFile? profileImage,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      // Upload profile image if provided
      if (profileImage != null) {
        final imageUrl = await _cloudinaryService.uploadImage(profileImage);
        updateData['profileImageUrl'] = imageUrl;
      }

      // Add bio if provided
      if (bio != null) {
        updateData['bio'] = bio;
      }

      // Add city if provided
      if (city != null) {
        updateData['city'] = city;
      }

      if (updateData.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ No data to update');
        }
        return;
      }

      await _firestore
          .collection(FirestoreCollections.users)
          .doc(sellerId)
          .update(updateData);

      if (kDebugMode) {
        debugPrint('✅ Seller profile updated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating seller profile: $e');
      }
      rethrow;
    }
  }

  /// Gets all products by a seller with real-time updates
  Stream<List<ProductModel>> getSellerProductsStream(String sellerId) {
    try {
      return _firestore
          .collection(FirestoreCollections.products)
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating seller products stream: $e');
      }
      rethrow;
    }
  }
}
