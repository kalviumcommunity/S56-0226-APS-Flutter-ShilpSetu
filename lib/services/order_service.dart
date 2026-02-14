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
    required String paymentMethod,
    required String paymentStatus,
  }) async {
    try {
      if (cartItems.isEmpty) {
        throw Exception('Cart is empty');
      }

      // Step 1: Validate and deduct stock using transaction
      await _validateAndDeductStock(cartItems);

      // Step 2: Group cart items by sellerId
      final Map<String, List<CartItem>> itemsBySeller = {};
      for (final cartItem in cartItems) {
        final sellerId = cartItem.product.sellerId;
        if (!itemsBySeller.containsKey(sellerId)) {
          itemsBySeller[sellerId] = [];
        }
        itemsBySeller[sellerId]!.add(cartItem);
      }

      // Step 3: Create one order per seller
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
          'paymentMethod': paymentMethod,
          'paymentStatus': paymentStatus,
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

  /// Validates stock availability and deducts stock using Firestore transaction
  /// Throws exception if any product has insufficient stock
  Future<void> _validateAndDeductStock(List<CartItem> cartItems) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Step 1: Read all product documents
        final Map<String, DocumentSnapshot> productDocs = {};
        
        for (final cartItem in cartItems) {
          final productRef = _firestore
              .collection(FirestoreCollections.products)
              .doc(cartItem.product.id);
          
          final productDoc = await transaction.get(productRef);
          
          if (!productDoc.exists) {
            throw Exception('Product "${cartItem.product.title}" no longer exists');
          }
          
          productDocs[cartItem.product.id] = productDoc;
        }

        // Step 2: Validate stock for all products
        final List<String> insufficientStockProducts = [];
        
        for (final cartItem in cartItems) {
          final productDoc = productDocs[cartItem.product.id]!;
          final data = productDoc.data() as Map<String, dynamic>?;
          final currentStock = data?['stock'] ?? 0;
          final isActive = data?['isActive'] ?? false;
          
          if (!isActive) {
            throw Exception('Product "${cartItem.product.title}" is no longer available');
          }
          
          if (currentStock < cartItem.quantity) {
            insufficientStockProducts.add(
              '${cartItem.product.title} (Available: $currentStock, Requested: ${cartItem.quantity})'
            );
          }
        }

        // If any product has insufficient stock, throw exception
        if (insufficientStockProducts.isNotEmpty) {
          throw Exception(
            'Insufficient stock for:\n${insufficientStockProducts.join('\n')}'
          );
        }

        // Step 3: Deduct stock for all products
        for (final cartItem in cartItems) {
          final productRef = _firestore
              .collection(FirestoreCollections.products)
              .doc(cartItem.product.id);
          
          final productDoc = productDocs[cartItem.product.id]!;
          final data = productDoc.data() as Map<String, dynamic>?;
          final currentStock = data?['stock'] ?? 0;
          final newStock = currentStock - cartItem.quantity;
          
          transaction.update(productRef, {'stock': newStock});
          
          if (kDebugMode) {
            debugPrint('✅ Stock deducted for ${cartItem.product.title}: $currentStock → $newStock');
          }
        }
      });
      
      if (kDebugMode) {
        debugPrint('✅ Stock validation and deduction completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Stock validation/deduction failed: $e');
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
