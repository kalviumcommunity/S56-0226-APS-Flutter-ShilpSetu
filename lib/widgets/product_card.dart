import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_model.dart';
import '../core/constants/colors.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  bool get _isOutOfStock => product.stock == 0;
  bool get _isLowStock => product.stock > 0 && product.stock <= 5;

  Color get _stockColor {
    if (_isOutOfStock) return AppColors.error;
    if (_isLowStock) return AppColors.warning;
    return AppColors.success;
  }

  String get _stockLabel {
    if (_isOutOfStock) return 'Out of Stock';
    if (_isLowStock) return 'Low: ${product.stock} left';
    return '${product.stock} in stock';
  }

  IconData get _stockIcon {
    if (_isOutOfStock) return Icons.remove_shopping_cart_outlined;
    if (_isLowStock) return Icons.warning_amber_rounded;
    return Icons.inventory_2_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          // Thumbnail — padded, rounded square
          Padding(
            padding: const EdgeInsets.all(10),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 95,
                    height: 140,
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      placeholder: (_, __) => Container(
                        color: AppColors.secondarySurface,
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryAccent),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.secondarySurface,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined,
                              size: 28, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
                // ACTIVE / INACTIVE badge
                Positioned(
                  top: 5,
                  left: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: product.isActive
                          ? AppColors.success
                          : AppColors.error,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product.isActive ? 'ACTIVE' : 'INACTIVE',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                if (_isOutOfStock)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(color: Colors.black.withOpacity(0.35)),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.lightSageTint,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product.category.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mutedForestGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                      const Spacer(),
                      if (product.reviewCount > 0) ...[
                        const Icon(Icons.star_rounded,
                            size: 13, color: AppColors.mutedGold),
                        const SizedBox(width: 2),
                        Text(
                          '${product.averageRating.toStringAsFixed(1)} (${product.reviewCount})',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _stockColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: _stockColor.withOpacity(0.25), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_stockIcon, size: 12, color: _stockColor),
                        const SizedBox(width: 4),
                        Text(
                          _stockLabel,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _stockColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _formatDate(product.createdAt.toDate()),
                        style: GoogleFonts.inter(
                            fontSize: 10, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      _ActionBtn(
                        icon: Icons.edit_outlined,
                        color: AppColors.primaryAccent,
                        bg: AppColors.lightSageTint,
                        tooltip: 'Edit',
                        onTap: onEdit,
                      ),
                      const SizedBox(width: 8),
                      _ActionBtn(
                        icon: Icons.delete_outline,
                        color: AppColors.error,
                        bg: AppColors.error.withOpacity(0.1),
                        tooltip: 'Delete',
                        onTap: () => _showDeleteDialog(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.delete_outline, color: AppColors.error, size: 22),
          SizedBox(width: 8),
          Text('Delete Product'),
        ]),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.textPrimary, height: 1.5),
            children: [
              const TextSpan(text: 'Delete '),
              TextSpan(
                text: '"${product.title}"',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(
                  text:
                      '? This cannot be undone and the listing will be permanently removed.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final d = DateTime.now().difference(date);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    if (d.inDays == 1) return 'yesterday';
    if (d.inDays < 7) return '${d.inDays}d ago';
    if (d.inDays < 30) return '${(d.inDays / 7).floor()}w ago';
    if (d.inDays < 365) return '${(d.inDays / 30).floor()}mo ago';
    return '${(d.inDays / 365).floor()}y ago';
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.bg,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(icon, size: 17, color: color),
          ),
        ),
      ),
    );
  }
}
