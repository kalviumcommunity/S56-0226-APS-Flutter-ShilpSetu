import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/admin_service.dart';
import '../../core/constants/colors.dart';
import '../../utils/number_formatter.dart';

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  final AdminService _adminService = AdminService();
  String _selectedFilter = 'All';

  List<ProductModel> _applyFilter(List<ProductModel> products) {
    switch (_selectedFilter) {
      case 'Active':
        return products.where((p) => p.isActive).toList();
      case 'Inactive':
        return products.where((p) => !p.isActive).toList();
      default:
        return products;
    }
  }

  Future<void> _toggleProductStatus(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.isActive ? 'Disable Product?' : 'Enable Product?'),
        content: Text(
          product.isActive
              ? 'This product will be hidden from buyers.'
              : 'This product will be visible to buyers again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: product.isActive ? Colors.red : Colors.green,
            ),
            child: Text(product.isActive ? 'Disable' : 'Enable'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _adminService.toggleProductStatus(product.id, !product.isActive);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                product.isActive
                    ? 'Product disabled successfully'
                    : 'Product enabled successfully',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: const Text(
          'This will permanently delete the product. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _adminService.deleteProduct(product.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product deleted successfully'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Chips
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: ['All', 'Active', 'Inactive'].map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                ),
              );
            }).toList(),
          ),
        ),

        // Products List
        Expanded(
          child: StreamBuilder<List<ProductModel>>(
            stream: _adminService.getAllProductsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

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
              final filteredProducts = _applyFilter(allProducts);

              if (filteredProducts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_outlined, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No products found',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: ClipRRect(
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
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                      title: Text(
                        product.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('By: ${product.sellerName}'),
                          Text('Category: ${product.category}'),
                          Text(
                            NumberFormatter.formatCurrency(product.price),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                product.isActive
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 16,
                                color: product.isActive ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                product.isActive ? 'Active' : 'Disabled',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: product.isActive ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: Row(
                              children: [
                                Icon(
                                  product.isActive ? Icons.block : Icons.check_circle,
                                  size: 20,
                                  color: product.isActive ? Colors.red : Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Text(product.isActive ? 'Disable' : 'Enable'),
                              ],
                            ),
                            onTap: () => Future.delayed(
                              Duration.zero,
                              () => _toggleProductStatus(product),
                            ),
                          ),
                          PopupMenuItem(
                            child: const Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                            onTap: () => Future.delayed(
                              Duration.zero,
                              () => _deleteProduct(product),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
