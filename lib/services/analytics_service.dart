import 'package:flutter/foundation.dart';
import '../models/analytics_model.dart';
import '../models/order_model.dart';
import '../models/time_period.dart';
import '../models/top_product.dart';

/// Helper class for aggregating product sales data
class _ProductSales {
  final String productId;
  final String title;
  final String imageUrl;
  int unitsSold;
  double revenue;

  _ProductSales({
    required this.productId,
    required this.title,
    required this.imageUrl,
    this.unitsSold = 0,
    this.revenue = 0.0,
  });
}

/// Service for calculating seller analytics from order data
class AnalyticsService {
  /// Calculates all analytics metrics from order list
  AnalyticsModel calculateMetrics({
    required List<OrderModel> orders,
    required int totalProducts,
    TimePeriod period = TimePeriod.allTime,
  }) {
    try {
      // Filter orders by time period
      final filteredOrders = _filterByPeriod(orders, period);

      // Calculate metrics
      final revenue = _calculateRevenue(filteredOrders);
      final avgOrderValue = _calculateAverageOrderValue(filteredOrders);
      final topProducts = _calculateTopProducts(filteredOrders);
      final recentOrders = _getRecentOrders(filteredOrders);

      if (kDebugMode) {
        debugPrint('📊 Analytics calculated: ${filteredOrders.length} orders, ₹$revenue revenue');
      }

      return AnalyticsModel(
        totalRevenue: revenue,
        totalOrders: filteredOrders.length,
        averageOrderValue: avgOrderValue,
        totalProducts: totalProducts,
        topProducts: topProducts,
        recentOrders: recentOrders,
        calculatedAt: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error calculating analytics: $e');
      }
      rethrow;
    }
  }

  /// Filters orders by time period
  List<OrderModel> _filterByPeriod(
    List<OrderModel> orders,
    TimePeriod period,
  ) {
    final startDate = period.startDate;
    
    if (startDate == null) {
      // All time - no filtering
      return orders;
    }

    // Filter orders created after start date
    return orders.where((order) {
      final orderDate = order.createdAt.toDate();
      return orderDate.isAfter(startDate);
    }).toList();
  }

  /// Calculates total revenue from delivered orders only
  double _calculateRevenue(List<OrderModel> orders) {
    return orders
        .where((order) => order.status == OrderModel.statusDelivered)
        .fold(0.0, (sum, order) => sum + order.totalAmount);
  }

  /// Calculates average order value
  /// Returns 0 if no delivered orders
  double _calculateAverageOrderValue(List<OrderModel> orders) {
    final deliveredOrders = orders
        .where((order) => order.status == OrderModel.statusDelivered)
        .toList();

    if (deliveredOrders.isEmpty) return 0.0;

    final revenue = _calculateRevenue(orders);
    return revenue / deliveredOrders.length;
  }

  /// Calculates top 5 products by revenue from delivered orders
  List<TopProduct> _calculateTopProducts(List<OrderModel> orders) {
    // Filter delivered orders only
    final deliveredOrders = orders
        .where((order) => order.status == OrderModel.statusDelivered)
        .toList();

    if (deliveredOrders.isEmpty) return [];

    // Aggregate sales by product
    final Map<String, _ProductSales> salesByProduct = {};

    for (final order in deliveredOrders) {
      for (final item in order.items) {
        if (!salesByProduct.containsKey(item.productId)) {
          salesByProduct[item.productId] = _ProductSales(
            productId: item.productId,
            title: item.title,
            imageUrl: item.imageUrl,
          );
        }

        salesByProduct[item.productId]!.unitsSold += item.quantity;
        salesByProduct[item.productId]!.revenue += item.totalPrice;
      }
    }

    // Sort by revenue descending and take top 5
    final topProducts = salesByProduct.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    return topProducts.take(5).map((sales) {
      return TopProduct(
        productId: sales.productId,
        title: sales.title,
        imageUrl: sales.imageUrl,
        unitsSold: sales.unitsSold,
        revenue: sales.revenue,
      );
    }).toList();
  }

  /// Gets the 5 most recent orders
  List<OrderModel> _getRecentOrders(List<OrderModel> orders) {
    if (orders.isEmpty) return [];

    // Sort by creation date descending
    final sortedOrders = List<OrderModel>.from(orders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Take first 5
    return sortedOrders.take(5).toList();
  }
}
