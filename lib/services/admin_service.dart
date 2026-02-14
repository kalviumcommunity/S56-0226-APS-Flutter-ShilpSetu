import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/firestore_collections.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/platform_stats.dart';
import '../models/review_with_product.dart';

/// Service for admin operations across the platform
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USER MANAGEMENT ====================

  /// Gets real-time stream of all users
  Stream<List<UserModel>> getAllUsersStream() {
    try {
      return _firestore
          .collection(FirestoreCollections.users)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting users stream: $e');
      }
      rethrow;
    }
  }

  /// Toggles user active status
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .update({'isActive': isActive});

      if (kDebugMode) {
        debugPrint('✅ User $userId status updated to: $isActive');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error toggling user status: $e');
      }
      rethrow;
    }
  }

  /// Updates user role (promote to admin, etc.)
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .update({'role': newRole});

      if (kDebugMode) {
        debugPrint('✅ User $userId role updated to: $newRole');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating user role: $e');
      }
      rethrow;
    }
  }

  // ==================== PRODUCT MANAGEMENT ====================

  /// Gets real-time stream of all products
  Stream<List<ProductModel>> getAllProductsStream() {
    try {
      return _firestore
          .collection(FirestoreCollections.products)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting products stream: $e');
      }
      rethrow;
    }
  }

  /// Toggles product active status
  Future<void> toggleProductStatus(String productId, bool isActive) async {
    try {
      await _firestore
          .collection(FirestoreCollections.products)
          .doc(productId)
          .update({'isActive': isActive});

      if (kDebugMode) {
        debugPrint('✅ Product $productId status updated to: $isActive');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error toggling product status: $e');
      }
      rethrow;
    }
  }

  /// Deletes a product permanently
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore
          .collection(FirestoreCollections.products)
          .doc(productId)
          .delete();

      if (kDebugMode) {
        debugPrint('✅ Product $productId deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting product: $e');
      }
      rethrow;
    }
  }

  // ==================== ORDER MONITORING ====================

  /// Gets real-time stream of all orders
  Stream<List<OrderModel>> getAllOrdersStream() {
    try {
      return _firestore
          .collection(FirestoreCollections.orders)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting orders stream: $e');
      }
      
      // Fallback without orderBy if index missing
      return _firestore
          .collection(FirestoreCollections.orders)
          .snapshots()
          .map((snapshot) {
        final orders = snapshot.docs
            .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
            .toList();
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return orders;
      });
    }
  }

  // ==================== REVIEW MODERATION ====================

  /// Gets all reviews across all products
  Future<List<ReviewWithProduct>> getAllReviews() async {
    try {
      final List<ReviewWithProduct> allReviews = [];

      // Get all products
      final productsSnapshot = await _firestore
          .collection(FirestoreCollections.products)
          .get();

      // For each product, get its reviews
      for (final productDoc in productsSnapshot.docs) {
        final productData = productDoc.data();
        final reviewsSnapshot = await _firestore
            .collection(FirestoreCollections.products)
            .doc(productDoc.id)
            .collection('reviews')
            .get();

        for (final reviewDoc in reviewsSnapshot.docs) {
          final reviewData = reviewDoc.data();
          
          // Get buyer name
          String buyerName = 'Unknown';
          try {
            final buyerDoc = await _firestore
                .collection(FirestoreCollections.users)
                .doc(reviewData['buyerId'])
                .get();
            if (buyerDoc.exists) {
              buyerName = buyerDoc.data()?['name'] ?? 'Unknown';
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ Could not fetch buyer name: $e');
            }
          }

          allReviews.add(ReviewWithProduct(
            reviewId: reviewDoc.id,
            productId: productDoc.id,
            productTitle: productData['title'] ?? 'Unknown Product',
            buyerId: reviewData['buyerId'] ?? '',
            buyerName: buyerName,
            rating: reviewData['rating'] ?? 0,
            comment: reviewData['comment'] ?? '',
            createdAt: (reviewData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ));
        }
      }

      // Sort by date descending
      allReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (kDebugMode) {
        debugPrint('✅ Fetched ${allReviews.length} reviews');
      }

      return allReviews;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting all reviews: $e');
      }
      rethrow;
    }
  }

  /// Deletes a review
  Future<void> deleteReview(String productId, String reviewId) async {
    try {
      await _firestore
          .collection(FirestoreCollections.products)
          .doc(productId)
          .collection('reviews')
          .doc(reviewId)
          .delete();

      if (kDebugMode) {
        debugPrint('✅ Review $reviewId deleted from product $productId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting review: $e');
      }
      rethrow;
    }
  }

  // ==================== PLATFORM ANALYTICS ====================

  /// Calculates platform-wide statistics
  Future<PlatformStats> getPlatformStats() async {
    try {
      // Get all users
      final usersSnapshot = await _firestore
          .collection(FirestoreCollections.users)
          .get();
      
      final users = usersSnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();

      final totalUsers = users.length;
      final totalSellers = users.where((u) => u.role == 'seller').length;
      final totalBuyers = users.where((u) => u.role == 'buyer').length;

      // Get all products
      final productsSnapshot = await _firestore
          .collection(FirestoreCollections.products)
          .get();
      final totalProducts = productsSnapshot.docs.length;

      // Get all orders
      final ordersSnapshot = await _firestore
          .collection(FirestoreCollections.orders)
          .get();
      
      final orders = ordersSnapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();

      final totalOrders = orders.length;
      final totalRevenue = orders
          .where((order) => order.status == OrderModel.statusDelivered)
          .fold(0.0, (sum, order) => sum + order.totalAmount);

      if (kDebugMode) {
        debugPrint('✅ Platform stats calculated: $totalUsers users, $totalOrders orders, ₹$totalRevenue revenue');
      }

      return PlatformStats(
        totalUsers: totalUsers,
        totalSellers: totalSellers,
        totalBuyers: totalBuyers,
        totalProducts: totalProducts,
        totalOrders: totalOrders,
        totalRevenue: totalRevenue,
        calculatedAt: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error calculating platform stats: $e');
      }
      rethrow;
    }
  }
}
