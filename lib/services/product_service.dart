import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../core/constants/firestore_collections.dart';
import 'cloudinary_service.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  Future<void> addProduct({
    required String sellerId,
    required String sellerName,
    required String title,
    required String description,
    required double price,
    required String category,
    required XFile imageFile,
  }) async {
    try {
      // Generate productId BEFORE upload
      final productRef = _firestore.collection(FirestoreCollections.products).doc();
      final productId = productRef.id;

      // Upload image to Cloudinary
      final imageUrl = await _cloudinaryService.uploadImage(imageFile);

      // Create product document in Firestore
      await productRef.set({
        'sellerId': sellerId,
        'sellerName': sellerName,
        'title': title,
        'description': description,
        'price': price,
        'category': category,
        'imageUrl': imageUrl,
        'isActive': true,
        'createdAt': Timestamp.now(),
      });

      if (kDebugMode) {
        print('✅ Product added successfully with ID: $productId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding product: $e');
      }
      throw Exception('Failed to add product: $e');
    }
  }

  Future<List<ProductModel>> getSellerProducts(String sellerId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.products)
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching seller products: $e');
      }
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<List<ProductModel>> getAllActiveProducts() async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.products)
          .where('isActive', isEqualTo: true)
          .get();

      final products = snapshot.docs.map((doc) => ProductModel.fromMap(doc.data(), doc.id)).toList();
      
      // Sort by createdAt descending in Dart (avoids composite index requirement)
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return products;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching active products: $e');
      }
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection(FirestoreCollections.products).doc(productId).delete();
      if (kDebugMode) {
        print('✅ Product deleted successfully: $productId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting product: $e');
      }
      throw Exception('Failed to delete product: $e');
    }
  }

  Future<void> updateProduct({
    required String productId,
    required String title,
    required String description,
    required double price,
    required String category,
    XFile? imageFile,
  }) async {
    try {
      final updateData = {
        'title': title,
        'description': description,
        'price': price,
        'category': category,
      };

      // Upload new image if provided
      if (imageFile != null) {
        final imageUrl = await _cloudinaryService.uploadImage(imageFile);
        updateData['imageUrl'] = imageUrl;
      }

      await _firestore.collection(FirestoreCollections.products).doc(productId).update(updateData);
      if (kDebugMode) {
        print('✅ Product updated successfully: $productId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating product: $e');
      }
      throw Exception('Failed to update product: $e');
    }
  }
}
