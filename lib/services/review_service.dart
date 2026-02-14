import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/review_model.dart';
import '../core/constants/firestore_collections.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adds a review for a product and updates product rating
  /// Uses transaction to ensure atomic updates
  /// Prevents duplicate reviews per order
  Future<void> addReview({
    required String productId,
    required String buyerId,
    required String buyerName,
    required String orderId,
    required int rating,
    required String comment,
  }) async {
    try {
      // Validate rating
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      // Step 1: Check if review already exists (outside transaction for better performance)
      final existingReviewQuery = await _firestore
          .collection(FirestoreCollections.products)
          .doc(productId)
          .collection('reviews')
          .where('orderId', isEqualTo: orderId)
          .where('buyerId', isEqualTo: buyerId)
          .limit(1)
          .get();

      if (existingReviewQuery.docs.isNotEmpty) {
        throw Exception('You have already reviewed this product from this order');
      }

      // Step 2: Run transaction for atomic updates
      await _firestore.runTransaction((transaction) async {
        // READ PHASE: Fetch product document first (all reads must come before writes)
        final productRef = _firestore
            .collection(FirestoreCollections.products)
            .doc(productId);

        final productDoc = await transaction.get(productRef);

        if (!productDoc.exists) {
          throw Exception('Product not found');
        }

        final productData = productDoc.data() as Map<String, dynamic>;
        final currentAvgRating = (productData['averageRating'] ?? 0).toDouble();
        final currentReviewCount = productData['reviewCount'] ?? 0;

        // Calculate new average rating
        final newReviewCount = currentReviewCount + 1;
        final newAvgRating = 
            ((currentAvgRating * currentReviewCount) + rating) / newReviewCount;

        // WRITE PHASE: Now perform all writes
        // Write 1: Create review document
        final reviewRef = _firestore
            .collection(FirestoreCollections.products)
            .doc(productId)
            .collection('reviews')
            .doc();

        final reviewData = {
          'productId': productId,
          'buyerId': buyerId,
          'buyerName': buyerName,
          'orderId': orderId,
          'rating': rating,
          'comment': comment,
          'createdAt': FieldValue.serverTimestamp(),
        };

        transaction.set(reviewRef, reviewData);

        // Write 2: Update product with new rating
        transaction.update(productRef, {
          'averageRating': newAvgRating,
          'reviewCount': newReviewCount,
        });

        if (kDebugMode) {
          debugPrint('✅ Review added successfully');
          debugPrint('   Product: $productId');
          debugPrint('   New average rating: ${newAvgRating.toStringAsFixed(2)}');
          debugPrint('   Total reviews: $newReviewCount');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error adding review: $e');
      }
      rethrow;
    }
  }

  /// Gets all reviews for a product with real-time updates
  Stream<List<ReviewModel>> getProductReviews(String productId) {
    try {
      return _firestore
          .collection(FirestoreCollections.products)
          .doc(productId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating reviews stream: $e');
      }
      rethrow;
    }
  }

  /// Checks if a buyer has already reviewed a product from a specific order
  Future<bool> hasReviewed({
    required String productId,
    required String orderId,
    required String buyerId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.products)
          .doc(productId)
          .collection('reviews')
          .where('orderId', isEqualTo: orderId)
          .where('buyerId', isEqualTo: buyerId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking review status: $e');
      }
      return false;
    }
  }

  /// Gets review statistics for a product
  Future<Map<String, dynamic>> getReviewStats(String productId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.products)
          .doc(productId)
          .collection('reviews')
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalReviews': 0,
          'ratingDistribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        };
      }

      final ratings = snapshot.docs.map((doc) => doc.data()['rating'] as int).toList();
      final totalReviews = ratings.length;
      final averageRating = ratings.reduce((a, b) => a + b) / totalReviews;

      // Calculate rating distribution
      final distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      for (final rating in ratings) {
        distribution[rating] = (distribution[rating] ?? 0) + 1;
      }

      return {
        'averageRating': averageRating,
        'totalReviews': totalReviews,
        'ratingDistribution': distribution,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching review stats: $e');
      }
      rethrow;
    }
  }
}
