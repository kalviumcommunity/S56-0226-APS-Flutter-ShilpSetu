import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../utils/number_formatter.dart';

/// List item widget displaying a recent order summary
class RecentOrderItem extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;

  const RecentOrderItem({
    super.key,
    required this.order,
    this.onTap,
  });

  Color _getStatusColor() {
    switch (order.status) {
      case OrderModel.statusPending:
        return Colors.orange;
      case OrderModel.statusAccepted:
        return Colors.blue;
      case OrderModel.statusShipped:
        return Colors.purple;
      case OrderModel.statusDelivered:
        return Colors.green;
      case OrderModel.statusCancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    switch (order.status) {
      case OrderModel.statusPending:
        return 'Pending';
      case OrderModel.statusAccepted:
        return 'Accepted';
      case OrderModel.statusShipped:
        return 'Shipped';
      case OrderModel.statusDelivered:
        return 'Delivered';
      case OrderModel.statusCancelled:
        return 'Cancelled';
      default:
        return order.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            // Status Indicator
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Order Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Order #${order.id.substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        NumberFormatter.formatCurrency(order.totalAmount),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getStatusLabel(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(),
                          ),
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
                        NumberFormatter.formatRelativeTime(
                          order.createdAt.toDate(),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow Icon
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
