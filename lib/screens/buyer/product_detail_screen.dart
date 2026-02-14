import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/product_model.dart';
import '../../models/review_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/review_service.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../seller/seller_profile_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.title),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  product.imageUrl,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    height: 300,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.broken_image, size: 50)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      product.title,
                      style: AppTextStyles.title,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      const Icon(Icons.currency_rupee, size: 20),
                      Text(
                        product.price.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                product.category,
                style: AppTextStyles.subtitle,
              ),

              // Rating Display
              if (product.reviewCount > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      product.averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${product.reviewCount} ${product.reviewCount == 1 ? 'review' : 'reviews'})',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),
              Text(
                'Description',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 8),
              Text(
                product.description,
                style: const TextStyle(fontSize: 16, height: 1.4),
              ),

              const SizedBox(height: 16),
              Text(
                'Seller',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SellerProfileScreen(sellerId: product.sellerId),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Text(
                          product.sellerName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          product.sellerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              // Stock Information
              const SizedBox(height: 16),
              _buildStockInfo(product),

              // Reviews Section
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Customer Reviews',
                    style: AppTextStyles.subtitle.copyWith(fontSize: 18),
                  ),
                  if (product.reviewCount > 0)
                    TextButton(
                      onPressed: () {
                        // Could navigate to full reviews page
                      },
                      child: const Text('See all'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _buildReviewsList(product.id),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: product.stock > 0
                          ? () {
                              context.read<CartProvider>().addToCart(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${product.title} added to cart'),
                                  duration: const Duration(seconds: 2),
                                  action: SnackBarAction(
                                    label: 'VIEW CART',
                                    onPressed: () {
                                      Navigator.of(context).pushNamed('/cart');
                                    },
                                  ),
                                ),
                              );
                            }
                          : null, // Disabled if out of stock
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(product.stock > 0 ? 'Add to Cart' : 'Out of Stock'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: product.stock > 0 ? AppColors.primary : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsList(String productId) {
    final reviewService = ReviewService();

    return StreamBuilder<List<ReviewModel>>(
      stream: reviewService.getProductReviews(productId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load reviews',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No reviews yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Be the first to review this product',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Show first 3 reviews
        final displayReviews = reviews.take(3).toList();

        return Column(
          children: displayReviews.map((review) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            review.buyerName[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.buyerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  ...List.generate(5, (index) {
                                    return Icon(
                                      index < review.rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 16,
                                      color: Colors.amber,
                                    );
                                  }),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDate(review.createdAt.toDate()),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      review.comment,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStockInfo(ProductModel product) {
    if (product.stock == 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text(
              'Out of Stock',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    } else if (product.stock <= 5) {
      // Low stock warning
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(
              'Only ${product.stock} left in stock!',
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    } else {
      // In stock
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text(
              'In Stock (${product.stock} available)',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
  }
}
