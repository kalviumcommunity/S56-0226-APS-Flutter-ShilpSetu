import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String productId;
  final String buyerId;
  final String buyerName;
  final String orderId;
  final int rating; // 1-5
  final String comment;
  final Timestamp createdAt;

  ReviewModel({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.buyerName,
    required this.orderId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ReviewModel(
      id: documentId,
      productId: map['productId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? 'Anonymous',
      orderId: map['orderId'] ?? '',
      rating: map['rating'] ?? 0,
      comment: map['comment'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
    };
  }
}
