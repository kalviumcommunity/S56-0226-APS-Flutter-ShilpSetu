import 'package:flutter/material.dart';
import '../models/top_product.dart';
import '../utils/number_formatter.dart';

/// List item widget displaying a top-selling product
class TopProductItem extends StatelessWidget {
  final TopProduct product;

  const TopProductItem({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              product.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                width: 60,
                height: 60,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${product.unitsSold} ${product.unitsSold == 1 ? 'unit' : 'units'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                    Text(
                      NumberFormatter.formatCurrency(product.revenue),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
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
