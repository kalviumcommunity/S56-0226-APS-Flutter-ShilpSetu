import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/sort_option.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

  List<ProductModel> sellerProducts = [];
  List<ProductModel> allProducts = [];
  List<ProductModel> filteredProducts = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  String? errorMessage;
  DocumentSnapshot? _lastProductSnapshot;
  bool hasMoreProducts = true;
  static const int pageSize = 10;

  // Filter and sort state
  String searchQuery = '';
  String? selectedCategory;
  double? minRating;
  double? minPrice;
  double? maxPrice;
  SortOption sortOption = SortOption.newest;

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

  /// Updates search query and applies filters
  void updateSearchQuery(String query) {
    searchQuery = query;
    applyFilters();
  }

  /// Updates selected category and applies filters
  void updateCategory(String? category) {
    selectedCategory = category;
    applyFilters();
  }

  /// Updates minimum rating filter and applies filters
  void updateMinRating(double? rating) {
    minRating = rating;
    applyFilters();
  }

  /// Updates price range filter and applies filters
  void updatePriceRange(double? min, double? max) {
    minPrice = min;
    maxPrice = max;
    applyFilters();
  }

  /// Updates sort option and applies filters
  void updateSortOption(SortOption option) {
    sortOption = option;
    applyFilters();
  }

  /// Resets all filters to default
  void resetFilters() {
    searchQuery = '';
    selectedCategory = null;
    minRating = null;
    minPrice = null;
    maxPrice = null;
    sortOption = SortOption.newest;
    applyFilters();
  }

  /// Applies all active filters and sorting to the product list
  void applyFilters() {
    // Start with all active products
    List<ProductModel> result = List.from(allProducts);

    // Apply search filter (case insensitive, partial match)
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((product) {
        return product.title.toLowerCase().contains(query);
      }).toList();
    }

    // Apply category filter
    if (selectedCategory != null && selectedCategory!.isNotEmpty) {
      result = result.where((product) {
        return product.category == selectedCategory;
      }).toList();
    }

    // Apply minimum rating filter
    if (minRating != null) {
      result = result.where((product) {
        return product.averageRating >= minRating!;
      }).toList();
    }

    // Apply price range filter
    if (minPrice != null) {
      result = result.where((product) {
        return product.price >= minPrice!;
      }).toList();
    }

    if (maxPrice != null) {
      result = result.where((product) {
        return product.price <= maxPrice!;
      }).toList();
    }

    // Apply sorting
    switch (sortOption) {
      case SortOption.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.priceLowHigh:
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceHighLow:
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.highestRated:
        result.sort((a, b) {
          // Products with no reviews go to the end
          if (a.reviewCount == 0 && b.reviewCount == 0) return 0;
          if (a.reviewCount == 0) return 1;
          if (b.reviewCount == 0) return -1;
          return b.averageRating.compareTo(a.averageRating);
        });
        break;
    }

    filteredProducts = result;
    notifyListeners();
  }

  /// Gets list of unique categories from all products
  List<String> getAvailableCategories() {
    final categories = allProducts.map((p) => p.category).toSet().toList();
    categories.sort();
    return categories;
  }

  /// Checks if any filters are active
  bool get hasActiveFilters {
    return searchQuery.isNotEmpty ||
        selectedCategory != null ||
        minRating != null ||
        minPrice != null ||
        maxPrice != null ||
        sortOption != SortOption.newest;
  }
}
