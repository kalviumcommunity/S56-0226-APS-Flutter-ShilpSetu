import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../utils/number_formatter.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../widgets/status_badge.dart';

/// Earthy Artisan Design System - Recent Order Item
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
        return AppColors.warning;
      case OrderModel.statusAccepted:
        return AppColors.mutedForestGreen;
      case OrderModel.statusShipped:
        return AppColors.softMutedGreen;
      case OrderModel.statusDelivered:
        return AppColors.success;
      case OrderModel.statusCancelled:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status Indicator
            Container(
              width: 4,
              height: 48,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Order #${order.id.substring(0, 8)}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.darkSlate,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        NumberFormatter.formatCurrency(order.totalAmount),
                        style: AppTextStyles.bodyBold.copyWith(
                          color: AppColors.forestJade,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getStatusLabel(),
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '•',
                          style: AppTextStyles.caption,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          NumberFormatter.formatRelativeTime(
                            order.createdAt.toDate(),
                          ),
                          style: AppTextStyles.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow Icon
            if (onTap != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
