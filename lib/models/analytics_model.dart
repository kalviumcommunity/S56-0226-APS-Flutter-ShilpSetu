import 'order_model.dart';
import 'top_product.dart';

/// Model containing all analytics data for a seller
class AnalyticsModel {
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final int totalProducts;
  final List<TopProduct> topProducts;
  final List<OrderModel> recentOrders;
  final DateTime calculatedAt;

  AnalyticsModel({
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.totalProducts,
    required this.topProducts,
    required this.recentOrders,
    required this.calculatedAt,
  });
}
