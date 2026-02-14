import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class OrderHistoryScreen extends StatefulWidget {
  final String buyerId;

  const OrderHistoryScreen({super.key, required this.buyerId});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final OrderService _orderService = OrderService();

  Future<void> _cancelOrder(String orderId) async {
    // Show confirmation dialog
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _orderService.cancelOrder(orderId);
      
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

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

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
              final date = order.createdAt.toDate();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Header
                      Row(
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
                                Text(
                                  _formatDate(date),
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
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
                        ],
                      ),
                      const Divider(height: 24),

                      // Order Items
                      Text(
                        'Items (${order.items.length})',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 8),
                      ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.imageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) =>
                                        Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.broken_image, size: 24),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: AppTextStyles.body,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Qty: ${item.quantity}',
                                        style: AppTextStyles.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.currency_rupee, size: 14),
                                    Text(
                                      item.totalPrice.toStringAsFixed(2),
                                      style: AppTextStyles.body,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )),

                      const Divider(height: 24),

                      // Payment Information
                      Row(
                        children: [
                          Icon(
                            _getPaymentIcon(order.paymentMethod),
                            size: 16,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getPaymentMethodLabel(order.paymentMethod),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getPaymentStatusColor(order.paymentStatus)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.paymentStatus.toUpperCase(),
                              style: TextStyle(
                                color: _getPaymentStatusColor(order.paymentStatus),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 24),

                      // Total Amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.currency_rupee, size: 18),
                              Text(
                                order.totalAmount.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Status Message
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getStatusColor(order.status).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getStatusIcon(order.status),
                              size: 20,
                              color: _getStatusColor(order.status),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getStatusMessage(order.status),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _getStatusColor(order.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Cancel Order Button
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
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info_outline;
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Waiting for seller to accept your order';
      case 'accepted':
        return 'Seller confirmed your order and is preparing it';
      case 'shipped':
        return 'Your order is on the way!';
      case 'delivered':
        return 'Order delivered successfully';
      case 'cancelled':
        return 'This order has been cancelled';
      default:
        return 'Order status: $status';
    }
  }

  IconData _getPaymentIcon(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'cod':
        return Icons.money;
      case 'razorpay':
        return Icons.payment;
      case 'upi':
        return Icons.account_balance;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  String _getPaymentMethodLabel(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'cod':
        return 'Cash on Delivery';
      case 'razorpay':
        return 'Razorpay';
      case 'upi':
        return 'UPI';
      case 'card':
        return 'Credit/Debit Card';
      default:
        return paymentMethod.toUpperCase();
    }
  }

  Color _getPaymentStatusColor(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
