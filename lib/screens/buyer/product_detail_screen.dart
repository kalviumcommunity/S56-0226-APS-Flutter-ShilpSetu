import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

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
              Text(
                product.sellerName,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Placeholder: implement purchase/checkout flow later
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const SizedBox(
                  width: double.infinity,
                  child: Center(child: Text('Buy Now')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
