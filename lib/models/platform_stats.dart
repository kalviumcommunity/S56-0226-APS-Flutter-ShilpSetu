/// Model containing platform-wide statistics
class PlatformStats {
  final int totalUsers;
  final int totalSellers;
  final int totalBuyers;
  final int totalProducts;
  final int totalOrders;
  final double totalRevenue;
  final DateTime calculatedAt;

  PlatformStats({
    required this.totalUsers,
    required this.totalSellers,
    required this.totalBuyers,
    required this.totalProducts,
    required this.totalOrders,
    required this.totalRevenue,
    required this.calculatedAt,
  });
}
