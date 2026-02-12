import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';

class TestProductScreen extends StatefulWidget {
  const TestProductScreen({super.key});

  @override
  State<TestProductScreen> createState() => _TestProductScreenState();
}

class _TestProductScreenState extends State<TestProductScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProducts();
    });
  }

  Future<void> _fetchProducts() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        print('❌ No user logged in');
        return;
      }

      await productProvider.fetchSellerProducts(currentUser.uid);
      
      print('✅ Fetched ${productProvider.sellerProducts.length} products for seller: ${currentUser.uid}');
    } catch (e) {
      print('❌ Error fetching products: $e');
    }
  }

  Future<bool> _requestPermissions() async {
    final status = await Permission.photos.request();
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo permission is required')),
        );
      }
      return false;
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable photo permission in settings'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: openAppSettings,
            ),
          ),
        );
      }
      return false;
    }
    return false;
  }

  Future<void> _testAddProduct() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login first')),
          );
        }
        return;
      }

      // Request permissions
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        print('❌ Permission denied');
        return;
      }

      // Pick image
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) {
        print('No image selected');
        return;
      }

      print('📸 Image selected: ${image.name}');

      setState(() {
        _isUploading = true;
      });

      // Add product using provider
      await productProvider.addProduct(
        sellerId: currentUser.uid,
        sellerName: currentUser.email ?? 'Test Seller',
        title: 'Test Handmade Pottery',
        description: 'Beautiful handcrafted pottery made with traditional techniques',
        price: 499.99,
        category: 'Pottery',
        imageFile: image,
      );

      print('✅ Product added to Firestore successfully!');

      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully! Check Firestore console'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error adding product: $e');
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Product Service'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchProducts,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(
                Icons.add_shopping_cart,
                size: 60,
                color: Colors.blue,
              ),
              const SizedBox(height: 10),
              const Text(
                'Test Product Service',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (currentUser != null) ...[
                Text(
                  'Logged in as:',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  currentUser.email ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'User ID: ${currentUser.uid}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ] else ...[
                const Text(
                  'Not logged in',
                  style: TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 30),
              if (_isUploading)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Adding product to Firestore...'),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: currentUser != null ? _testAddProduct : null,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Add Test Product'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Products',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${productProvider.sellerProducts.length} items',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (productProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (productProvider.sellerProducts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('No products yet. Add one to test!'),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: productProvider.sellerProducts.length,
                  itemBuilder: (context, index) {
                    final product = productProvider.sellerProducts[index];
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
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.error),
                              );
                            },
                          ),
                        ),
                        title: Text(product.title),
                        subtitle: Text(
                          '₹${product.price.toStringAsFixed(2)} • ${product.category}',
                        ),
                        trailing: Icon(
                          product.isActive ? Icons.check_circle : Icons.cancel,
                          color: product.isActive ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
