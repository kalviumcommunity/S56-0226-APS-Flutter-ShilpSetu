import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import 'add_product_screen.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sellerId =
          context.read<AuthProvider>().currentUser!.uid;
      context.read<ProductProvider>().fetchSellerProducts(sellerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Store'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, _) {
          if (productProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (productProvider.sellerProducts.isEmpty) {
            return const Center(
              child: Text(
                'No products yet.\nAdd your first product!',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: productProvider.sellerProducts.length,
            itemBuilder: (context, index) {
              final product = productProvider.sellerProducts[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: Image.network(
                    product.imageUrl,
                    width: 60,
                    fit: BoxFit.cover,
                  ),
                  title: Text(product.title),
                  subtitle: Text('₹${product.price.toStringAsFixed(2)}'),
                  trailing: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddProductScreen(product: product),
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
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final sellerId =
                              context.read<AuthProvider>().currentUser!.uid;
                          await context
                              .read<ProductProvider>()
                              .deleteProduct(product.id, sellerId);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddProductScreen(),
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
        child: const Icon(Icons.add),
      ),
    );
  }
}
