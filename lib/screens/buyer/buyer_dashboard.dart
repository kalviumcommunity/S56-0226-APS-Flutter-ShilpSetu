import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/product_model.dart';
import '../../models/sort_option.dart';
import '../../services/product_service.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../widgets/filter_bottom_sheet.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import 'manage_address_screen.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  
  // Filter state
  String searchQuery = '';
  String? selectedCategory;
  double? minRating;
  double? minPrice;
  double? maxPrice;
  SortOption sortOption = SortOption.newest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProductModel> _applyFilters(List<ProductModel> products) {
    List<ProductModel> result = List.from(products);

    // Apply search filter
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
          if (a.reviewCount == 0 && b.reviewCount == 0) return 0;
          if (a.reviewCount == 0) return 1;
          if (b.reviewCount == 0) return -1;
          return b.averageRating.compareTo(a.averageRating);
        });
        break;
    }

    return result;
  }

  List<String> _getAvailableCategories(List<ProductModel> products) {
    final categories = products.map((p) => p.category).toSet().toList();
    categories.sort();
    return categories;
  }

  void _showFilterBottomSheet(List<ProductModel> allProducts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        categories: _getAvailableCategories(allProducts),
        selectedCategory: selectedCategory,
        minRating: minRating,
        minPrice: minPrice,
        maxPrice: maxPrice,
        onCategoryChanged: (category) {
          setState(() {
            selectedCategory = category;
          });
        },
        onMinRatingChanged: (rating) {
          setState(() {
            minRating = rating;
          });
        },
        onPriceRangeChanged: (min, max) {
          setState(() {
            minPrice = min;
            maxPrice = max;
          });
        },
        onReset: () {
          setState(() {
            selectedCategory = null;
            minRating = null;
            minPrice = null;
            maxPrice = null;
          });
          Navigator.pop(context);
        },
        onApply: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  bool get _hasActiveFilters {
    return searchQuery.isNotEmpty ||
        selectedCategory != null ||
        minRating != null ||
        minPrice != null ||
        maxPrice != null ||
        sortOption != SortOption.newest;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;
    final cartProvider = context.watch<CartProvider>();
    final buyerId = authProvider.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Buyer Dashboard'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.text,
        actions: [
          // Manage Addresses
          IconButton(
            icon: const Icon(Icons.location_on),
            tooltip: 'Manage Addresses',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ManageAddressScreen(userId: buyerId),
                ),
              );
            },
          ),
          // My Orders
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'My Orders',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderHistoryScreen(buyerId: buyerId),
                ),
              );
            },
          ),
          // Cart with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                tooltip: 'Cart',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
              if (cartProvider.totalItems > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${cartProvider.totalItems}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.name ?? "Buyer"}!',
              style: AppTextStyles.title,
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),

            const SizedBox(height: 12),

            // Filter and Sort Row
            StreamBuilder<List<ProductModel>>(
              stream: _productService.getAllActiveProductsStream(limit: 50),
              builder: (context, snapshot) {
                final allProducts = snapshot.data ?? [];
                
                return Row(
                  children: [
                    // Filter Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showFilterBottomSheet(allProducts),
                        icon: Icon(
                          _hasActiveFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                          size: 20,
                        ),
                        label: Text(_hasActiveFilters ? 'Filters (Active)' : 'Filters'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _hasActiveFilters ? AppColors.primary : Colors.grey[700],
                          side: BorderSide(
                            color: _hasActiveFilters ? AppColors.primary : Colors.grey[300]!,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Sort Dropdown
                    Expanded(
                      child: DropdownButtonFormField<SortOption>(
                        value: sortOption,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.sort, size: 20),
                        ),
                        items: SortOption.values.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text(
                              option.shortLabel,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              sortOption = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // Content - Real-time product stream with filters
            Expanded(
              child: StreamBuilder<List<ProductModel>>(
                stream: _productService.getAllActiveProductsStream(limit: 50),
                builder: (context, snapshot) {
                  // Loading state
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Error state
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 60, color: Colors.red),
                          const SizedBox(height: 16),
                          const Text('Failed to load products'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final allProducts = snapshot.data ?? [];
                  final products = _applyFilters(allProducts);

                  // Empty state
                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _hasActiveFilters
                                ? 'No products match your filters'
                                : 'No products available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (_hasActiveFilters) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  searchQuery = '';
                                  selectedCategory = null;
                                  minRating = null;
                                  minPrice = null;
                                  maxPrice = null;
                                  sortOption = SortOption.newest;
                                  _searchController.clear();
                                });
                              },
                              child: const Text('Clear Filters'),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  // Products grid
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        child: _BuyerProductCard(product: product),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuyerProductCard extends StatelessWidget {
  final ProductModel product;

  const _BuyerProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    product.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                ),
                // Stock badge
                if (product.stock == 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'OUT OF STOCK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else if (product.stock <= 5)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ONLY ${product.stock} LEFT',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: AppTextStyles.bodyBold,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  product.category,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 6),
                // Rating display
                if (product.reviewCount > 0)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        product.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${product.reviewCount})',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.currency_rupee, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      product.price.toStringAsFixed(2),
                      style: AppTextStyles.price,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
