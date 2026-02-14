import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../services/address_service.dart';
import '../../models/address_model.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import 'order_success_screen.dart';
import 'select_address_screen.dart';
import 'manage_address_screen.dart';
import 'payment_selection_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final OrderService _orderService = OrderService();
  final AddressService _addressService = AddressService();
  bool _isPlacingOrder = false;

  Future<void> _handlePlaceOrder() async {
    final cartProvider = context.read<CartProvider>();
    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final buyerId = authProvider.currentUser?.uid;
    if (buyerId == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please login to place an order')),
      );
      return;
    }

    if (cartProvider.items.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    // Check if user has any addresses
    final hasAddresses = await _addressService.hasAddresses(buyerId);
    
    if (!hasAddresses) {
      // Show dialog and navigate to add address
      if (mounted) {
        final shouldAddAddress = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('No Delivery Address'),
            content: const Text('Please add a delivery address to place your order.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Add Address'),
              ),
            ],
          ),
        );

        if (shouldAddAddress == true && mounted) {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => ManageAddressScreen(userId: buyerId),
            ),
          );
        }
      }
      return;
    }

    // Navigate to address selection
    if (mounted) {
      final selectedAddress = await navigator.push<AddressModel>(
        MaterialPageRoute(
          builder: (_) => SelectAddressScreen(userId: buyerId),
        ),
      );

      if (selectedAddress == null) {
        // User cancelled address selection
        return;
      }

      // Navigate to payment selection
      final paymentData = await navigator.push<Map<String, String>>(
        MaterialPageRoute(
          builder: (_) => PaymentSelectionScreen(
            totalAmount: cartProvider.totalPrice,
          ),
        ),
      );

      if (paymentData == null) {
        // User cancelled payment selection
        return;
      }

      // Proceed with order creation
      await _createOrder(
        selectedAddress,
        paymentData['paymentMethod']!,
        paymentData['paymentStatus']!,
      );
    }
  }

  Future<void> _createOrder(
    AddressModel address,
    String paymentMethod,
    String paymentStatus,
  ) async {
    final cartProvider = context.read<CartProvider>();
    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final buyerId = authProvider.currentUser?.uid;
    if (buyerId == null) return;

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final totalAmount = cartProvider.totalPrice;
      
      // Create shipping address snapshot
      final shippingAddress = {
        'fullName': address.fullName,
        'phoneNumber': address.phoneNumber,
        'addressLine1': address.addressLine1,
        'addressLine2': address.addressLine2,
        'city': address.city,
        'state': address.state,
        'pincode': address.pincode,
      };

      // Create orders (grouped by seller)
      final orderIds = await _orderService.createOrders(
        buyerId: buyerId,
        cartItems: cartProvider.items,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
      );

      // Clear cart on success
      cartProvider.clearCart();

      // Navigate to success screen
      if (mounted) {
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => OrderSuccessScreen(
              orderCount: orderIds.length,
              totalAmount: totalAmount,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final items = cartProvider.items;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Cart'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final cartItem = items[index];
                      final product = cartItem.product;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // Product Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  product.imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) =>
                                      Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image),
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
                                      style: AppTextStyles.bodyBold,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.currency_rupee, size: 14),
                                        Text(
                                          product.price.toStringAsFixed(2),
                                          style: AppTextStyles.body,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Stock warning
                                    if (cartItem.quantity > product.stock)
                                      Text(
                                        'Only ${product.stock} available',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    else if (product.stock <= 5)
                                      Text(
                                        'Only ${product.stock} left',
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        // Decrease button
                                        IconButton(
                                          onPressed: () {
                                            cartProvider.decreaseQuantity(product.id);
                                          },
                                          icon: const Icon(Icons.remove_circle_outline),
                                          iconSize: 24,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 12),

                                        // Quantity
                                        Text(
                                          '${cartItem.quantity}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: cartItem.quantity > product.stock
                                                ? Colors.red
                                                : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Increase button
                                        IconButton(
                                          onPressed: cartItem.quantity < product.stock
                                              ? () {
                                                  cartProvider.increaseQuantity(product.id);
                                                }
                                              : null, // Disabled if at max stock
                                          icon: Icon(
                                            Icons.add_circle_outline,
                                            color: cartItem.quantity < product.stock
                                                ? null
                                                : Colors.grey,
                                          ),
                                          iconSize: 24,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Remove button
                              Column(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      cartProvider.removeFromCart(product.id);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${product.title} removed from cart'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.currency_rupee, size: 14),
                                      Text(
                                        cartItem.totalPrice.toStringAsFixed(2),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Total and Place Order
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.currency_rupee, size: 20),
                              Text(
                                cartProvider.totalPrice.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isPlacingOrder ? null : _handlePlaceOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isPlacingOrder
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Place Order',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
