import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

  List<ProductModel> sellerProducts = [];
  bool isLoading = false;
  String? errorMessage;

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
      errorMessage = e.toString();
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
    XFile? imageFile,
  }) async {
    try {
      await _productService.updateProduct(
        productId: productId,
        title: title,
        description: description,
        price: price,
        category: category,
        imageFile: imageFile,
      );

      // Refresh seller products after updating
      await fetchSellerProducts(sellerId);
    } catch (e) {
      rethrow;
    }
  }
}
