import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

  List<ProductModel> sellerProducts = [];
  List<ProductModel> allProducts = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  String? errorMessage;
  DocumentSnapshot? _lastProductSnapshot;
  bool hasMoreProducts = true;
  static const int pageSize = 10;

  Future<void> fetchSellerProducts(String sellerId) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      sellerProducts = await _productService.getSellerProducts(sellerId);

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = 'Unable to load your products. Please try again.';
      notifyListeners();
    }
  }

  Future<void> fetchAllProducts() async {
    try {
      isLoading = true;
      errorMessage = null;
      allProducts.clear();
      _lastProductSnapshot = null;
      hasMoreProducts = true;
      notifyListeners();

      allProducts = await _productService.getAllActiveProducts(limit: pageSize);
      _lastProductSnapshot = null;
      hasMoreProducts = allProducts.length >= pageSize;

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = 'Unable to load products. Please try again.';
      notifyListeners();
    }
  }

  Future<void> fetchNextPage() async {
    if (isLoadingMore || !hasMoreProducts) return;

    try {
      isLoadingMore = true;
      notifyListeners();

      if (_lastProductSnapshot == null && allProducts.isNotEmpty) {
        // Get the last product doc snapshot for pagination
        final lastProduct = allProducts.last;
        _lastProductSnapshot =
            await FirebaseFirestore.instance
                .collection('products')
                .doc(lastProduct.id)
                .get();
      }

      final nextProducts = await _productService.getAllActiveProducts(
        limit: pageSize,
        startAfter: _lastProductSnapshot,
      );

      if (nextProducts.isEmpty) {
        hasMoreProducts = false;
      } else {
        allProducts.addAll(nextProducts);
        _lastProductSnapshot = null;
        hasMoreProducts = nextProducts.length >= pageSize;
      }

      isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      isLoadingMore = false;
      errorMessage = 'Failed to load more products.';
      notifyListeners();
    }
  }

  Future<void> addProduct({
    required String sellerId,
    required String sellerName,
    required String title,
    required String description,
    required double price,
    required String category,
    required int stock,
    required XFile imageFile,
  }) async {
    try {
      await _productService.addProduct(
        sellerId: sellerId,
        sellerName: sellerName,
        title: title,
        description: description,
        price: price,
        category: category,
        stock: stock,
        imageFile: imageFile,
      );

      // Refresh seller products after adding
      await fetchSellerProducts(sellerId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId, String sellerId) async {
    try {
      await _productService.deleteProduct(productId);

      // Refresh seller products after deleting
      await fetchSellerProducts(sellerId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProduct({
    required String productId,
    required String sellerId,
    required String title,
    required String description,
    required double price,
    required String category,
    required int stock,
    XFile? imageFile,
  }) async {
    try {
      await _productService.updateProduct(
        productId: productId,
        title: title,
        description: description,
        price: price,
        category: category,
        stock: stock,
        imageFile: imageFile,
      );

      // Refresh seller products after updating
      await fetchSellerProducts(sellerId);
    } catch (e) {
      rethrow;
    }
  }
}
