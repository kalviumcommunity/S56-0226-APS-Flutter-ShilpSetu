import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_model.dart';
import '../core/constants/colors.dart';

class BuyerProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const BuyerProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  State<BuyerProductCard> createState() => _BuyerProductCardState();
}

class _BuyerProductCardState extends State<BuyerProductCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _shimmerController;

  bool get _isOutOfStock => widget.product.stock == 0;
  bool get _isLowStock =>
      widget.product.stock > 0 && widget.product.stock <= 5;
  bool get _isNew => DateTime.now()
          .difference(widget.product.createdAt.toDate())
          .inDays <=
      7;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _isOutOfStock ? null : widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Opacity(
          opacity: _isOutOfStock ? 0.72 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                _buildImageSection(),
                Flexible(child: _buildInfoSection()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Image Section ────────────────────────────────────────────────────────

  Widget _buildImageSection() {
    return Stack(
      children: [
        // Image
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: SizedBox(
            height: 158,
            width: double.infinity,
            child: CachedNetworkImage(
              imageUrl: widget.product.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => _buildShimmer(),
              errorWidget: (_, __, ___) => _buildImagePlaceholder(),
            ),
          ),
        ),

        // Bottom gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // NEW badge — top left
        if (_isNew && !_isOutOfStock)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.mutedForestGreen,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'NEW',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),

        // OUT OF STOCK overlay
        if (_isOutOfStock)
          Positioned.fill(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                color: Colors.black.withOpacity(0.42),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'OUT OF STOCK',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB94040),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildShimmer() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (_, __) {
        return Container(
          height: 158,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                _shimmerController.value.clamp(0.0, 1.0),
                (_shimmerController.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: const [
                Color(0xFFEDE8E0),
                Color(0xFFF8F4EE),
                Color(0xFFEDE8E0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 158,
      color: AppColors.secondarySurface,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 36,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  // ─── Info Section ─────────────────────────────────────────────────────────

  Widget _buildInfoSection() {
    final bool hasRating = widget.product.reviewCount > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Row: Category tag + Star rating
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.lightSageTint,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.product.category.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedForestGreen,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (hasRating) ...[
                const SizedBox(width: 6),
                const Icon(Icons.star_rounded,
                    size: 13, color: AppColors.mutedGold),
                const SizedBox(width: 2),
                Text(
                  '${widget.product.averageRating.toStringAsFixed(1)} (${widget.product.reviewCount})',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),

          // Title — Expanded so it absorbs leftover space and never overflows
          Expanded(
            child: Text(
              widget.product.title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _isOutOfStock
                    ? AppColors.textSecondary
                    : AppColors.deepCharcoalBrown,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),

          // Seller name
          Text(
            'by ${widget.product.sellerName}',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),

          // Price row
          Text(
            '₹${widget.product.price.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _isOutOfStock
                  ? AppColors.textSecondary
                  : AppColors.mutedForestGreen,
            ),
          ),

          // Low stock warning
          if (_isLowStock) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.bolt_rounded,
                    size: 12, color: AppColors.mutedGold),
                const SizedBox(width: 2),
                Text(
                  'Only ${widget.product.stock} left!',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedGold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
