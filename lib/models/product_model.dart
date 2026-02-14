import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String title;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final bool isActive;
  final Timestamp createdAt;
  final int stock;

  ProductModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.isActive,
    required this.createdAt,
    this.stock = 0,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductModel(
      id: documentId,
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      stock: map['stock'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt,
      'stock': stock,
    };
  }

  // Helper to check if product is in stock
  bool get isInStock => stock > 0;

  // Helper to check if quantity is available
  bool hasStock(int quantity) => stock >= quantity;
}
