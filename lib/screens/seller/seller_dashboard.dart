import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';
import '../../core/constants/colors.dart';
import 'add_product_screen.dart';
import 'seller_orders_screen.dart';
import 'edit_seller_profile_screen.dart';
import 'analytics_screen.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sellerId = context.read<AuthProvider>().currentUser!.uid;
      context.read<ProductProvider>().fetchSellerProducts(sellerId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.userModel?.name ?? 'Seller';
    final sellerId = authProvider.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Store',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              userName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.text,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EditSellerProfileScreen(),
                ),
              );
            },
          ),
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(
              icon: Icon(Icons.inventory_2),
              text: 'Products',
            ),
            Tab(
              icon: Icon(Icons.shopping_bag),
              text: 'Orders',
            ),
            Tab(
              icon: Icon(Icons.analytics),
              text: 'Analytics',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          SellerOrdersScreen(sellerId: sellerId),
          Consumer<ProductProvider>(
            builder: (context, productProvider, _) {
              return AnalyticsScreen(
                sellerId: sellerId,
                totalProducts: productProvider.sellerProducts.length,
              );
            },
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddProductScreen(),
                  ),
                );

                if (context.mounted) {
                  final sellerId = context.read<AuthProvider>().currentUser!.uid;
                  context.read<ProductProvider>().fetchSellerProducts(sellerId);
                }
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            )
          : null,
    );
  }

  Widget _buildProductsTab() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        if (productProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (productProvider.sellerProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 52,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No products yet',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the button below to list\nyour first handcrafted item',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final products = productProvider.sellerProducts;
        final activeCount = products.where((p) => p.isActive).length;
        final outOfStockCount = products.where((p) => p.stock == 0).length;
        final lowStockCount =
            products.where((p) => p.stock > 0 && p.stock <= 5).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats strip
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  _StatChip(
                    label: 'Total',
                    value: '${products.length}',
                    color: AppColors.primaryAccent,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'Active',
                    value: '$activeCount',
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  if (lowStockCount > 0)
                    _StatChip(
                      label: 'Low stock',
                      value: '$lowStockCount',
                      color: AppColors.warning,
                    ),
                  if (outOfStockCount > 0) ...[
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'Out',
                      value: '$outOfStockCount',
                      color: AppColors.error,
                    ),
                  ],
                ],
              ),
            ),

            // Product List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: productProvider.sellerProducts.length,
                itemBuilder: (context, index) {
                  final product = productProvider.sellerProducts[index];

                  return ProductCard(
                    product: product,
                    onEdit: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddProductScreen(product: product),
                        ),
                      );

                      if (context.mounted) {
                        final sellerId =
                            context.read<AuthProvider>().currentUser!.uid;
                        context
                            .read<ProductProvider>()
                            .fetchSellerProducts(sellerId);
                      }
                    },
                    onDelete: () async {
                      final sellerId =
                          context.read<AuthProvider>().currentUser!.uid;
                      await context
                          .read<ProductProvider>()
                          .deleteProduct(product.id, sellerId);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Stats chip ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.80),
            ),
          ),
        ],
      ),
    );
  }
}
