import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String buyerId;
  final String sellerId;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final Map<String, dynamic>? shippingAddress;
  final String paymentMethod;
  final String paymentStatus;

  // Valid status values: pending, accepted, shipped, delivered, cancelled
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusShipped = 'shipped';
  static const String statusDelivered = 'delivered';
  static const String statusCancelled = 'cancelled';

  OrderModel({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.shippingAddress,
    this.paymentMethod = 'cod',
    this.paymentStatus = 'pending',
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String documentId) {
    final itemsList = (map['items'] as List<dynamic>?) ?? [];
    final items = itemsList.map((item) => OrderItem.fromMap(item)).toList();

    return OrderModel(
      id: documentId,
      buyerId: map['buyerId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      items: items,
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] as Timestamp?,
      shippingAddress: map['shippingAddress'] as Map<String, dynamic>?,
      paymentMethod: map['paymentMethod'] ?? 'cod',
      paymentStatus: map['paymentStatus'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'sellerId': sellerId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (shippingAddress != null) 'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
    };
  }

  // Helper to get next valid status
  String? getNextStatus() {
    switch (status) {
      case statusPending:
        return statusAccepted;
      case statusAccepted:
        return statusShipped;
      case statusShipped:
        return statusDelivered;
      case statusDelivered:
        return null; // No next status
      default:
        return null;
    }
  }

  // Helper to check if status transition is valid
  static bool isValidTransition(String currentStatus, String newStatus) {
    final validTransitions = {
      statusPending: [statusAccepted, statusCancelled],
      statusAccepted: [statusShipped, statusCancelled],
      statusShipped: [statusDelivered],
      statusDelivered: [],
      statusCancelled: [],
    };

    return validTransitions[currentStatus]?.contains(newStatus) ?? false;
  }

  // Helper to check if order can be cancelled
  bool get canBeCancelled {
    return status == statusPending || status == statusAccepted;
  }

  // Helper to check if order is in terminal state
  bool get isTerminal {
    return status == statusDelivered || status == statusCancelled;
  }
}

class OrderItem {
  final String productId;
  final String title;
  final double price;
  final int quantity;
  final String imageUrl;

  OrderItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      title: map['title'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'title': title,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }

  double get totalPrice => price * quantity;
}
