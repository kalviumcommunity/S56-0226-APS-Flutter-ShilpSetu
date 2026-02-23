import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../services/order_service.dart';
import '../../services/review_service.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import 'add_review_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  final String buyerId;

  const OrderHistoryScreen({super.key, required this.buyerId});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final OrderService _orderService = OrderService();
  final ReviewService _reviewService = ReviewService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _orderService.getOrdersByBuyer(widget.buyerId),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Failed to load orders: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data ?? [];

          // Empty state
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your orders will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          // Orders list
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderCard(
                order: order,
                buyerId: widget.buyerId,
                reviewService: _reviewService,
                orderService: _orderService,
              );
            },
          );
        },
      ),
    );
  }
}

// ── Isolated card widget — expand/collapse never rebuilds the list ──
class _OrderCard extends StatefulWidget {
  final OrderModel order;
  final String buyerId;
  final ReviewService reviewService;
  final OrderService orderService;

  const _OrderCard({
    required this.order,
    required this.buyerId,
    required this.reviewService,
    required this.orderService,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isExpanded = false;

  OrderModel get order => widget.order;

  Future<void> _cancelOrder(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
          'Are you sure you want to cancel this order? Stock will be restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.orderService.cancelOrder(orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) =>
      DateFormat('MMM dd, yyyy • hh:mm a').format(date);

  String _formatShippingAddress(Map<String, dynamic> address) {
    final parts = <String>[
      address['addressLine1'] ?? '',
      if (address['addressLine2'] != null &&
          address['addressLine2'].toString().isNotEmpty)
        address['addressLine2'],
      address['city'] ?? '',
      address['state'] ?? '',
      address['pincode'] ?? '',
    ];
    return parts.where((p) => p.isNotEmpty).join(', ');
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':   return Colors.orange;
      case 'accepted':  return Colors.blue;
      case 'shipped':   return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default:          return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':   return 'Pending';
      case 'accepted':  return 'Accepted';
      case 'shipped':   return 'Shipped';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default:          return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':   return Icons.schedule;
      case 'accepted':  return Icons.check_circle_outline;
      case 'shipped':   return Icons.local_shipping;
      case 'delivered': return Icons.done_all;
      case 'cancelled': return Icons.cancel;
      default:          return Icons.info_outline;
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'pending':   return 'Waiting for seller to accept your order';
      case 'accepted':  return 'Seller confirmed your order and is preparing it';
      case 'shipped':   return 'Your order is on the way!';
      case 'delivered': return 'Order delivered successfully';
      case 'cancelled': return 'This order has been cancelled';
      default:          return 'Order status: $status';
    }
  }

  String _getCodStatusMessage(OrderModel o) {
    if (o.isCodPaymentPending) {
      return 'Please pay ₹${o.totalAmount.toStringAsFixed(2)} in cash to the delivery person / seller';
    }
    return 'Cash payment received ✓';
  }

  IconData _getPaymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cod':      return Icons.money;
      case 'razorpay': return Icons.payment;
      case 'upi':      return Icons.account_balance;
      case 'card':     return Icons.credit_card;
      default:         return Icons.payment;
    }
  }

  String _getPaymentMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cod':      return 'Cash on Delivery';
      case 'razorpay': return 'Razorpay';
      case 'upi':      return 'UPI';
      case 'card':     return 'Credit/Debit Card';
      default:         return method.toUpperCase();
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'paid':    return Colors.green;
      case 'failed':  return Colors.red;
      default:        return Colors.grey;
    }
  }

  ProductModel _createProductFromOrderItem(OrderItem item) {
    return ProductModel(
      id: item.productId,
      sellerId: '',
      sellerName: '',
      title: item.title,
      description: '',
      price: item.price,
      category: '',
      imageUrl: item.imageUrl,
      isActive: true,
      createdAt: Timestamp.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = order.createdAt.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tappable Header ──
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id.substring(0, 8)}',
                          style: AppTextStyles.bodyBold,
                        ),
                        const SizedBox(height: 4),
                        Text(_formatDate(date), style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusLabel(order.status).toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.primaryAccent,
                    size: 28,
                  ),
                ],
              ),
            ),
            const Divider(height: 24),

            // ── Items (always visible) ──
            Text('Items (${order.items.length})', style: AppTextStyles.subtitle),
            const SizedBox(height: 12),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.secondarySurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.secondarySurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.broken_image,
                              size: 28, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              style: AppTextStyles.body,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text('Qty: ${item.quantity}',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.currency_rupee,
                            size: 14, color: AppColors.primaryAccent),
                        Text(item.totalPrice.toStringAsFixed(2),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

            // ── Expanded Details ──
            if (_isExpanded) ...[
              const Divider(height: 24),
              _buildExpandedContent(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Delivery Address
        if (order.shippingAddress != null) ...[
          Text('Delivery Address', style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.person,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(order.shippingAddress!['fullName'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.phone,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(order.shippingAddress!['phoneNumber'] ?? ''),
                ]),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatShippingAddress(order.shippingAddress!),
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 24),
        ],

        // Payment
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Method', style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(_getPaymentIcon(order.paymentMethod),
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(_getPaymentMethodLabel(order.paymentMethod),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getPaymentStatusColor(order.paymentStatus)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                order.paymentStatus.toUpperCase(),
                style: TextStyle(
                  color: _getPaymentStatusColor(order.paymentStatus),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),

        // COD pending info banner
        if (order.isCodPaymentPending) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.money, size: 20, color: Colors.orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cash Payment Due',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            fontSize: 13),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _getCodStatusMessage(order),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.orange),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const Divider(height: 24),

        // Total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Amount',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(children: [
              const Icon(Icons.currency_rupee, size: 18),
              Text(
                order.totalAmount.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryAccent,
                ),
              ),
            ]),
          ],
        ),

        // Status message
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getStatusColor(order.status).withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: _getStatusColor(order.status).withOpacity(0.2)),
          ),
          child: Row(children: [
            Icon(_getStatusIcon(order.status),
                size: 20, color: _getStatusColor(order.status)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_getStatusMessage(order.status),
                  style: TextStyle(
                      fontSize: 13, color: _getStatusColor(order.status))),
            ),
          ]),
        ),

        // Cancel button
        if (order.status == 'pending' || order.status == 'accepted') ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _cancelOrder(order.id),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel Order'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],

        // Rate products (delivered)
        if (order.status == 'delivered') ...[
          const SizedBox(height: 12),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FutureBuilder<bool>(
                  future: widget.reviewService.hasReviewed(
                    productId: item.productId,
                    orderId: order.id,
                    buyerId: widget.buyerId,
                  ),
                  builder: (context, snapshot) {
                    final hasReviewed = snapshot.data ?? false;
                    if (hasReviewed) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('You reviewed: ${item.title}',
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                      );
                    }
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddReviewScreen(
                                product:
                                    _createProductFromOrderItem(item),
                                orderId: order.id,
                                buyerId: widget.buyerId,
                                buyerName: 'Buyer',
                              ),
                            ),
                          );
                          if (result == true && mounted) setState(() {});
                        },
                        icon: const Icon(Icons.star_rate),
                        label: Text('Rate: ${item.title}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    );
                  },
                ),
              )),
        ],
      ],
    );
  }
}
