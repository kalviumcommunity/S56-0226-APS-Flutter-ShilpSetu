import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/firestore_collections.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates multiple orders from cart items, grouped by seller
  /// Returns list of created orderIds
  /// Throws exception on error
  Future<List<String>> createOrders({
    required String buyerId,
    required List<CartItem> cartItems,
    required Map<String, dynamic> shippingAddress,
  }) async {
    try {
      if (cartItems.isEmpty) {
        throw Exception('Cart is empty');
      }

      // Group cart items by sellerId
      final Map<String, List<CartItem>> itemsBySeller = {};
      for (final cartItem in cartItems) {
        final sellerId = cartItem.product.sellerId;
        if (!itemsBySeller.containsKey(sellerId)) {
          itemsBySeller[sellerId] = [];
        }
        itemsBySeller[sellerId]!.add(cartItem);
      }

      // Create one order per seller
      final List<String> orderIds = [];
      
      for (final entry in itemsBySeller.entries) {
        final sellerId = entry.key;
        final sellerItems = entry.value;

        // Build items list with necessary fields (snapshot approach)
        final items = sellerItems.map((cartItem) {
          return {
            'productId': cartItem.product.id,
            'title': cartItem.product.title,
            'price': cartItem.product.price,
            'quantity': cartItem.quantity,
            'imageUrl': cartItem.product.imageUrl,
          };
        }).toList();

        // Calculate total amount for this seller's items
        final totalAmount = sellerItems.fold<double>(
          0.0,
          (sum, item) => sum + item.totalPrice,
        );

        // Build order document
        final orderData = {
          'buyerId': buyerId,
          'sellerId': sellerId,
          'items': items,
          'totalAmount': totalAmount,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'shippingAddress': shippingAddress,
        };

        // Create order in Firestore
        final orderRef = await _firestore
            .collection(FirestoreCollections.orders)
            .add(orderData);

        orderIds.add(orderRef.id);

        if (kDebugMode) {
          debugPrint('✅ Order created: ${orderRef.id}');
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Created ${orderIds.length} orders successfully');
      }

      return orderIds;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating orders: $e');
      }
      rethrow;
    }
  }

  /// Fetches all orders for a specific seller
  /// Returns list of OrderModel
  Future<List<OrderModel>> getOrdersBySeller(String sellerId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.orders)
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .get();

      final orders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();

      if (kDebugMode) {
        debugPrint('✅ Fetched ${orders.length} orders for seller');
      }

      return orders;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching orders: $e');
      }
      
      // Fallback: Try without orderBy if index is missing
      try {
        final snapshot = await _firestore
            .collection(FirestoreCollections.orders)
            .where('sellerId', isEqualTo: sellerId)
            .get();

        final orders = snapshot.docs
            .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
            .toList();

        // Sort in memory
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (kDebugMode) {
          debugPrint('✅ Fetched ${orders.length} orders (sorted in memory)');
        }

        return orders;
      } catch (fallbackError) {
        if (kDebugMode) {
          debugPrint('❌ Fallback failed: $fallbackError');
        }
        rethrow;
      }
    }
  }

  /// Fetches all orders for a specific buyer with real-time updates
  /// Returns Stream of OrderModel list
  Stream<List<OrderModel>> getOrdersByBuyer(String buyerId) {
    try {
      return _firestore
          .collection(FirestoreCollections.orders)
          .where('buyerId', isEqualTo: buyerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating buyer orders stream: $e');
      }
      
      // Fallback: Try without orderBy if index is missing
      return _firestore
          .collection(FirestoreCollections.orders)
          .where('buyerId', isEqualTo: buyerId)
          .snapshots()
          .map((snapshot) {
        final orders = snapshot.docs
            .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
            .toList();
        
        // Sort in memory
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        return orders;
      });
    }
  }

  /// Updates the status of an order
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore
          .collection(FirestoreCollections.orders)
          .doc(orderId)
          .update({'status': newStatus});

      if (kDebugMode) {
        debugPrint('✅ Order $orderId status updated to $newStatus');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating order status: $e');
      }
      rethrow;
    }
  }
}
