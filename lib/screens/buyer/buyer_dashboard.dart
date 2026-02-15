import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/product_model.dart';
import '../../models/sort_option.dart';
import '../../services/product_service.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/spacing.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../../widgets/buyer_product_card.dart';
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
        title: Text('Discover', style: AppTextStyles.sectionTitle),
        actions: [
          // Manage Addresses
          IconButton(
            icon: const Icon(Icons.location_on_outlined),
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
            icon: const Icon(Icons.receipt_long_outlined),
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
                icon: const Icon(Icons.shopping_bag_outlined),
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
                      color: AppColors.error,
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
            icon: const Icon(Icons.logout_outlined),
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
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user?.name ?? "there"}',
              style: AppTextStyles.pageTitle,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Find unique handcrafted items',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.md),

            // Search Bar
            TextField(
              controller: _searchController,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Search artisan products...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
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
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.mutedForestGreen,
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),

            const SizedBox(height: AppSpacing.sm),

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
                          size: 18,
                        ),
                        label: Text(_hasActiveFilters ? 'Filters' : 'Filter'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _hasActiveFilters 
                              ? AppColors.mutedForestGreen 
                              : AppColors.textSecondary,
                          side: BorderSide(
                            color: _hasActiveFilters 
                                ? AppColors.mutedForestGreen 
                                : AppColors.inputBorder,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

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
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.mutedForestGreen,
                              width: 1.5,
                            ),
                          ),
                          prefixIcon: const Icon(Icons.sort, size: 18),
                        ),
                        items: SortOption.values.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text(
                              option.shortLabel,
                              style: AppTextStyles.body.copyWith(fontSize: 14),
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

            const SizedBox(height: AppSpacing.md),

            // Content - Real-time product stream with filters
            Expanded(
              child: StreamBuilder<List<ProductModel>>(
                stream: _productService.getAllActiveProductsStream(limit: 50),
                builder: (context, snapshot) {
                  // Loading state
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.mutedForestGreen,
                        ),
                      ),
                    );
                  }

                  // Error state
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 60,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Failed to load products',
                            style: AppTextStyles.body,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mutedForestGreen,
                            ),
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
                            color: AppColors.textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _hasActiveFilters
                                ? 'No products match your filters'
                                : 'No products available',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (_hasActiveFilters) ...[
                            const SizedBox(height: AppSpacing.sm),
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
                              child: Text(
                                'Clear Filters',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.mutedForestGreen,
                                ),
                              ),
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
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return BuyerProductCard(
                        product: product,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: product),
                            ),
                          );
                        },
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
