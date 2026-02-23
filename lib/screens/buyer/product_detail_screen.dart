import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/product_model.dart';
import '../../models/review_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/review_service.dart';
import '../../core/constants/colors.dart';
import '../seller/seller_profile_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  String _formatDate(DateTime date) =>
      DateFormat('MMM dd, yyyy').format(date);

  bool get _hasOriginLocation =>
      product.originLat != null && product.originLng != null;

  Future<void> _openInGoogleMaps(BuildContext context) async {
    if (!_hasOriginLocation) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${product.originLat},${product.originLng}',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool inStock = product.stock > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: AppColors.secondarySurface,
            child: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      // ── Sticky bottom Add-to-Cart bar ──
      bottomNavigationBar: _buildBottomBar(context, inStock),
      body: CustomScrollView(
        slivers: [
          // ── Hero image ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  product.imageUrl,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: AppColors.secondarySurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.broken_image,
                          size: 60, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip + NEW badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lightSageTint,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          product.category,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                      ),
                      if (DateTime.now()
                              .difference(product.createdAt.toDate())
                              .inDays <=
                          7) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.mutedGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'NEW',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.mutedGold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title + Price row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.title,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepCharcoalBrown,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.currency_rupee,
                                  size: 18,
                                  color: AppColors.primaryAccent),
                              Text(
                                product.price.toStringAsFixed(2),
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryAccent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Rating row
                  if (product.reviewCount > 0) ...[
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < product.averageRating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 18,
                            color: AppColors.mutedGold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          product.averageRating.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.reviewCount} ${product.reviewCount == 1 ? 'review' : 'reviews'})',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Stock badge
                  _buildStockBadge(),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'About this product',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepCharcoalBrown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.6,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Seller card
                  Text(
                    'Sold by',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepCharcoalBrown,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          SellerProfileScreen(sellerId: product.sellerId),
                    )),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.lightSageTint,
                            child: Text(
                              product.sellerName.isNotEmpty
                                  ? product.sellerName[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.playfairDisplay(
                                color: AppColors.primaryAccent,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.sellerName,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'View shop →',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.primaryAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              size: 14, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),

                  // Origin map
                  if (_hasOriginLocation) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Craft Origin',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepCharcoalBrown,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                    product.originLat!, product.originLng!),
                                zoom: 13,
                              ),
                              markers: {
                                Marker(
                                  markerId: MarkerId('origin_${product.id}'),
                                  position: LatLng(
                                      product.originLat!, product.originLng!),
                                  infoWindow: InfoWindow(
                                    title: product.originCity ?? product.title,
                                  ),
                                ),
                              },
                              mapToolbarEnabled: false,
                              zoomControlsEnabled: false,
                              scrollGesturesEnabled: false,
                              rotateGesturesEnabled: false,
                              tiltGesturesEnabled: false,
                              myLocationButtonEnabled: false,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 16,
                                    color: AppColors.primaryAccent),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    product.originCity ?? 'Craft location',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      _openInGoogleMaps(context),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primaryAccent,
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Open in Maps'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Reviews ──
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Customer Reviews',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepCharcoalBrown,
                        ),
                      ),
                      if (product.reviewCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.mutedGold.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 14, color: AppColors.mutedGold),
                              const SizedBox(width: 4),
                              Text(
                                product.averageRating.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.mutedGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildReviewsList(product.id),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool inStock) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        border: const Border(
          top: BorderSide(color: AppColors.divider),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Price pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.currency_rupee,
                    size: 16, color: AppColors.primaryAccent),
                Text(
                  product.price.toStringAsFixed(2),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Add to cart button
          Expanded(
            child: Consumer<CartProvider>(
              builder: (context, cart, _) {
                final cartQty = cart.quantityInCart(product.id);
                final atStockCap = cartQty >= product.stock;
                final String label;
                final IconData icon;
                final Color bgColor;

                if (!inStock) {
                  label = 'Out of Stock';
                  icon = Icons.remove_shopping_cart;
                  bgColor = Colors.grey.shade400;
                } else if (atStockCap) {
                  label = 'In Cart ($cartQty/${product.stock})';
                  icon = Icons.shopping_cart;
                  bgColor = AppColors.mutedGold;
                } else {
                  label = cartQty > 0
                      ? 'Add More ($cartQty in cart)'
                      : 'Add to Cart';
                  icon = Icons.add_shopping_cart;
                  bgColor = AppColors.primaryAccent;
                }

                return ElevatedButton.icon(
                  onPressed: (inStock && !atStockCap)
                      ? () {
                          final added =
                              context.read<CartProvider>().addToCart(product);
                          if (added) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content:
                                      Text('${product.title} added to cart'),
                                  duration: const Duration(seconds: 2),
                                  action: SnackBarAction(
                                    label: 'VIEW CART',
                                    onPressed: () => Navigator.of(context)
                                        .pushNamed('/cart'),
                                  ),
                                ),
                              );
                          }
                        }
                      : null,
                  icon: Icon(icon, size: 20),
                  label: Text(
                    label,
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bgColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: atStockCap
                        ? AppColors.mutedGold.withOpacity(0.85)
                        : Colors.grey.shade300,
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockBadge() {
    if (product.stock == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 16),
            const SizedBox(width: 6),
            Text('Out of Stock',
                style: GoogleFonts.inter(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      );
    } else if (product.stock <= 5) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber, color: AppColors.warning, size: 16),
            const SizedBox(width: 6),
            Text('Only ${product.stock} left!',
                style: GoogleFonts.inter(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.success.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.success, size: 16),
            const SizedBox(width: 6),
            Text('In Stock · ${product.stock} available',
                style: GoogleFonts.inter(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      );
    }
  }

  Widget _buildReviewsList(String productId) {
    final reviewService = ReviewService();
    return StreamBuilder<List<ReviewModel>>(
      stream: reviewService.getProductReviews(productId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Failed to load reviews',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 14)),
          );
        }

        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.secondarySurface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.rate_review_outlined,
                    size: 40, color: AppColors.textSecondary),
                const SizedBox(height: 10),
                Text('No reviews yet',
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('Be the first to review this product',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return Column(
          children: reviews.take(3).map((review) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.lightSageTint,
                        child: Text(
                          review.buyerName.isNotEmpty
                              ? review.buyerName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.inter(
                            color: AppColors.primaryAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review.buyerName,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            Row(
                              children: [
                                ...List.generate(
                                  5,
                                  (i) => Icon(
                                    i < review.rating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 14,
                                    color: AppColors.mutedGold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDate(review.createdAt.toDate()),
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.textSecondary),
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
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textPrimary),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

