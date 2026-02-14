import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/seller_stats.dart';
import '../../models/product_model.dart';
import '../../services/seller_service.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../buyer/product_detail_screen.dart';

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;

  const SellerProfileScreen({super.key, required this.sellerId});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  final SellerService _sellerService = SellerService();

  String _formatDate(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Seller Profile'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
      body: FutureBuilder<UserModel?>(
        future: _sellerService.getSellerProfile(widget.sellerId),
        builder: (context, sellerSnapshot) {
          if (sellerSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (sellerSnapshot.hasError || sellerSnapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Failed to load seller profile'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final seller = sellerSnapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Profile Image
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary,
                        backgroundImage: seller.profileImageUrl != null
                            ? NetworkImage(seller.profileImageUrl!)
                            : null,
                        child: seller.profileImageUrl == null
                            ? Text(
                                seller.name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Name
                      Text(
                        seller.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // City
                      if (seller.city != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              seller.city!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),

                      // Member Since
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Member since ${_formatDate(seller.createdAt)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Stats Section
                FutureBuilder<SellerStats>(
                  future: _sellerService.getSellerStats(widget.sellerId),
                  builder: (context, statsSnapshot) {
                    final stats = statsSnapshot.data ?? SellerStats.empty();

                    return Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            icon: Icons.star,
                            label: 'Rating',
                            value: stats.overallRating > 0
                                ? stats.overallRating.toStringAsFixed(1)
                                : 'N/A',
                            color: Colors.amber,
                          ),
                          _buildStatItem(
                            icon: Icons.rate_review,
                            label: 'Reviews',
                            value: stats.totalReviewCount.toString(),
                            color: Colors.blue,
                          ),
                          _buildStatItem(
                            icon: Icons.inventory_2,
                            label: 'Products',
                            value: stats.activeProducts.toString(),
                            color: Colors.green,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Bio Section
                if (seller.bio != null && seller.bio!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About',
                          style: AppTextStyles.subtitle.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          seller.bio!,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Products Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Products',
                        style: AppTextStyles.subtitle.copyWith(fontSize: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Products Grid
                StreamBuilder<List<ProductModel>>(
                  stream: _sellerService.getSellerProductsStream(widget.sellerId),
                  builder: (context, productsSnapshot) {
                    if (productsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (productsSnapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: Text('Failed to load products')),
                      );
                    }

                    final products = productsSnapshot.data ?? [];
                    final activeProducts = products.where((p) => p.isActive).toList();

                    if (activeProducts.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No products available',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: activeProducts.length,
                      itemBuilder: (context, index) {
                        final product = activeProducts[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(product: product),
                              ),
                            );
                          },
                          child: _ProductCard(product: product),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
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
