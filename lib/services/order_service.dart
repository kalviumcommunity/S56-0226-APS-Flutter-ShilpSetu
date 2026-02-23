import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/firestore_collections.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates multiple orders from cart items, grouped by seller.
  ///
  /// Stock validation, stock deduction, and order document creation all happen
  /// inside a **single Firestore transaction**. Either every operation succeeds
  /// or the entire transaction is rolled back — no orphaned stock deductions.
  ///
  /// Returns the list of created order IDs.
  Future<List<String>> createOrders({
    required String buyerId,
    required List<CartItem> cartItems,
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
    required String paymentStatus,
  }) async {
    try {
      if (cartItems.isEmpty) {
        throw Exception('Cart is empty');
      }

      // Group cart items by sellerId before entering the transaction so
      // we can pre-compute order document references (needed for their IDs).
      final Map<String, List<CartItem>> itemsBySeller = {};
      for (final cartItem in cartItems) {
        itemsBySeller
            .putIfAbsent(cartItem.product.sellerId, () => [])
            .add(cartItem);
      }

      // Pre-generate one DocumentReference per seller-group so we know the
      // order IDs before the transaction begins (required for the return value).
      final Map<String, DocumentReference> orderRefsBySeller = {
        for (final sellerId in itemsBySeller.keys)
          sellerId: _firestore.collection(FirestoreCollections.orders).doc(),
      };

      // ── Single atomic transaction ──────────────────────────────────────────
      await _firestore.runTransaction((transaction) async {
        // ── READ PHASE ────────────────────────────────────────────────────────
        // Fetch every product document first. All reads must come before writes.
        final Map<String, DocumentSnapshot> productDocs = {};
        for (final cartItem in cartItems) {
          final productRef = _firestore
              .collection(FirestoreCollections.products)
              .doc(cartItem.product.id);
          final productDoc = await transaction.get(productRef);

          if (!productDoc.exists) {
            throw Exception(
                'Product "${cartItem.product.title}" no longer exists');
          }
          productDocs[cartItem.product.id] = productDoc;
        }

        // ── VALIDATION ────────────────────────────────────────────────────────
        final List<String> insufficientStockProducts = [];

        for (final cartItem in cartItems) {
          final data =
              productDocs[cartItem.product.id]!.data() as Map<String, dynamic>?;
          final currentStock = (data?['stock'] as num?)?.toInt() ?? 0;
          final isActive = data?['isActive'] as bool? ?? false;

          if (!isActive) {
            throw Exception(
                'Product "${cartItem.product.title}" is no longer available');
          }

          if (currentStock < cartItem.quantity) {
            insufficientStockProducts.add(
              '${cartItem.product.title} '
              '(Available: $currentStock, Requested: ${cartItem.quantity})',
            );
          }
        }

        if (insufficientStockProducts.isNotEmpty) {
          throw Exception(
            'Insufficient stock for:\n${insufficientStockProducts.join('\n')}',
          );
        }

        // ── WRITE PHASE ───────────────────────────────────────────────────────
        // 1. Deduct stock for every product
        for (final cartItem in cartItems) {
          final productRef = _firestore
              .collection(FirestoreCollections.products)
              .doc(cartItem.product.id);
          final data =
              productDocs[cartItem.product.id]!.data() as Map<String, dynamic>?;
          final currentStock = (data?['stock'] as num?)?.toInt() ?? 0;
          final newStock = currentStock - cartItem.quantity;

          transaction.update(productRef, {'stock': newStock});

          if (kDebugMode) {
            debugPrint(
              '📦 Stock deducted for ${cartItem.product.title}: '
              '$currentStock → $newStock',
            );
          }
        }

        // 2. Create one order document per seller-group
        for (final entry in itemsBySeller.entries) {
          final sellerId = entry.key;
          final sellerItems = entry.value;

          final items = sellerItems
              .map((cartItem) => {
                    'productId': cartItem.product.id,
                    'title': cartItem.product.title,
                    'price': cartItem.product.price,
                    'quantity': cartItem.quantity,
                    'imageUrl': cartItem.product.imageUrl,
                  })
              .toList();

          final totalAmount = sellerItems.fold<double>(
            0.0,
            (sum, item) => sum + item.totalPrice,
          );

          final orderData = {
            'buyerId': buyerId,
            'sellerId': sellerId,
            'items': items,
            'totalAmount': totalAmount,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
            'shippingAddress': shippingAddress,
            'paymentMethod': paymentMethod,
            'paymentStatus': paymentStatus,
          };

          transaction.set(orderRefsBySeller[sellerId]!, orderData);
        }
      });
      // ── End transaction ────────────────────────────────────────────────────

      final orderIds = orderRefsBySeller.values.map((ref) => ref.id).toList();

      if (kDebugMode) {
        debugPrint('✅ Created ${orderIds.length} orders atomically');
        for (final id in orderIds) {
          debugPrint('   Order: $id');
        }
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

  /// Updates the status of an order with validation
  /// Enforces valid status transitions: pending → accepted → shipped → delivered
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      // Fetch current order to validate transition
      final orderDoc = await _firestore
          .collection(FirestoreCollections.orders)
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final currentStatus = orderDoc.data()?['status'] ?? 'pending';

      // Validate status transition
      if (!OrderModel.isValidTransition(currentStatus, newStatus)) {
        throw Exception(
          'Invalid status transition: $currentStatus → $newStatus. '
          'Valid transitions: pending → accepted → shipped → delivered'
        );
      }

      // Update status with timestamp
      await _firestore
          .collection(FirestoreCollections.orders)
          .doc(orderId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Order $orderId status updated: $currentStatus → $newStatus');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating order status: $e');
      }
      rethrow;
    }
  }

  /// Marks a COD order's payment as collected (paid) by the seller.
  /// Only allowed when:  paymentMethod == 'cod'  AND  paymentStatus == 'pending'  AND  status == 'delivered'
  Future<void> markCodPaymentCollected(String orderId) async {
    try {
      final orderRef = _firestore
          .collection(FirestoreCollections.orders)
          .doc(orderId);

      final orderDoc = await orderRef.get();
      if (!orderDoc.exists) throw Exception('Order not found');

      final data = orderDoc.data()!;
      final paymentMethod = data['paymentMethod'] ?? '';
      final paymentStatus = data['paymentStatus'] ?? '';
      final status = data['status'] ?? '';

      if (paymentMethod != 'cod') {
        throw Exception('Payment method is not Cash on Delivery');
      }
      if (status != OrderModel.statusDelivered) {
        throw Exception('Order has not been delivered yet');
      }
      if (paymentStatus == OrderModel.paymentStatusPaid) {
        throw Exception('Payment is already marked as collected');
      }

      await orderRef.update({
        'paymentStatus': OrderModel.paymentStatusPaid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ COD payment marked as collected for order $orderId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error marking COD payment collected: $e');
      }
      rethrow;
    }
  }

  /// Cancels an order and restores stock using transaction
  /// Can only cancel orders with status: pending or accepted
  /// Throws exception if cancellation is not allowed or fails
  Future<void> cancelOrder(String orderId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Step 1: Fetch order document
        final orderRef = _firestore
            .collection(FirestoreCollections.orders)
            .doc(orderId);
        
        final orderDoc = await transaction.get(orderRef);
        
        if (!orderDoc.exists) {
          throw Exception('Order not found');
        }

        final orderData = orderDoc.data() as Map<String, dynamic>;
        final currentStatus = orderData['status'] ?? 'pending';

        // Step 2: Validate cancellation is allowed
        if (currentStatus == OrderModel.statusCancelled) {
          throw Exception('Order is already cancelled');
        }

        if (currentStatus == OrderModel.statusShipped) {
          throw Exception('Cannot cancel order - already shipped');
        }

        if (currentStatus == OrderModel.statusDelivered) {
          throw Exception('Cannot cancel order - already delivered');
        }

        if (currentStatus != OrderModel.statusPending && 
            currentStatus != OrderModel.statusAccepted) {
          throw Exception('Order cannot be cancelled at this stage');
        }

        // Step 3: Restore stock for each item
        final items = (orderData['items'] as List<dynamic>?) ?? [];
        
        for (final item in items) {
          final productId = item['productId'] as String;
          final quantity = item['quantity'] as int;

          final productRef = _firestore
              .collection(FirestoreCollections.products)
              .doc(productId);
          
          final productDoc = await transaction.get(productRef);
          
          if (productDoc.exists) {
            final productData = productDoc.data() as Map<String, dynamic>?;
            final currentStock = productData?['stock'] ?? 0;
            final restoredStock = currentStock + quantity;
            
            transaction.update(productRef, {'stock': restoredStock});
            
            if (kDebugMode) {
              debugPrint('✅ Stock restored for product $productId: $currentStock → $restoredStock');
            }
          } else {
            if (kDebugMode) {
              debugPrint('⚠️ Product $productId not found, skipping stock restoration');
            }
          }
        }

        // Step 4: Update order status to cancelled
        transaction.update(orderRef, {
          'status': OrderModel.statusCancelled,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (kDebugMode) {
          debugPrint('✅ Order $orderId cancelled successfully');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error cancelling order: $e');
      }
      rethrow;
    }
  }
}
