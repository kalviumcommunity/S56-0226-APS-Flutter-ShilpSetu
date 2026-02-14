import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/admin_service.dart';
import '../../core/constants/colors.dart';
import '../../utils/number_formatter.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  final AdminService _adminService = AdminService();
  String _selectedFilter = 'All';

  List<OrderModel> _applyFilter(List<OrderModel> orders) {
    switch (_selectedFilter) {
      case 'Pending':
        return orders.where((o) => o.status == OrderModel.statusPending).toList();
      case 'Accepted':
        return orders.where((o) => o.status == OrderModel.statusAccepted).toList();
      case 'Shipped':
        return orders.where((o) => o.status == OrderModel.statusShipped).toList();
      case 'Delivered':
        return orders.where((o) => o.status == OrderModel.statusDelivered).toList();
      case 'Cancelled':
        return orders.where((o) => o.status == OrderModel.statusCancelled).toList();
      default:
        return orders;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
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

  String _getStatusLabel(String status) {
    return status[0].toUpperCase() + status.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Chips
        Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Pending', 'Accepted', 'Shipped', 'Delivered', 'Cancelled']
                  .map((filter) {
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
        ),

        // Orders List
        Expanded(
          child: StreamBuilder<List<OrderModel>>(
            stream: _adminService.getAllOrdersStream(),
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
                      const Text('Failed to load orders'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final allOrders = snapshot.data ?? [];
              final filteredOrders = _applyFilter(allOrders);

              if (filteredOrders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No orders found',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) {
                  final order = filteredOrders[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        width: 4,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      title: Text(
                        'Order #${order.id.substring(0, 8)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${order.items.length} items'),
                          Text(
                            NumberFormatter.formatRelativeTime(order.createdAt.toDate()),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getStatusLabel(order.status),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(order.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        NumberFormatter.formatCurrency(order.totalAmount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
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
