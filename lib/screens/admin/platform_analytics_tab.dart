import 'package:flutter/material.dart';
import '../../models/platform_stats.dart';
import '../../services/admin_service.dart';
import '../../widgets/metric_card.dart';
import '../../utils/number_formatter.dart';

class PlatformAnalyticsTab extends StatefulWidget {
  const PlatformAnalyticsTab({super.key});

  @override
  State<PlatformAnalyticsTab> createState() => _PlatformAnalyticsTabState();
}

class _PlatformAnalyticsTabState extends State<PlatformAnalyticsTab> {
  final AdminService _adminService = AdminService();

  Future<PlatformStats> _fetchStats() async {
    return await _adminService.getPlatformStats();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlatformStats>(
      future: _fetchStats(),
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
                const Text('Failed to load analytics'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final stats = snapshot.data!;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Last Updated
                Text(
                  'Last updated: ${NumberFormatter.formatRelativeTime(stats.calculatedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),

                // Metrics Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    MetricCard(
                      title: 'Total Users',
                      value: NumberFormatter.formatNumber(stats.totalUsers),
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                    MetricCard(
                      title: 'Total Sellers',
                      value: NumberFormatter.formatNumber(stats.totalSellers),
                      icon: Icons.store,
                      color: Colors.purple,
                    ),
                    MetricCard(
                      title: 'Total Buyers',
                      value: NumberFormatter.formatNumber(stats.totalBuyers),
                      icon: Icons.shopping_cart,
                      color: Colors.green,
                    ),
                    MetricCard(
                      title: 'Total Products',
                      value: NumberFormatter.formatNumber(stats.totalProducts),
                      icon: Icons.inventory,
                      color: Colors.orange,
                    ),
                    MetricCard(
                      title: 'Total Orders',
                      value: NumberFormatter.formatNumber(stats.totalOrders),
                      icon: Icons.shopping_bag,
                      color: Colors.teal,
                    ),
                    MetricCard(
                      title: 'Total Revenue',
                      value: NumberFormatter.formatCurrency(stats.totalRevenue),
                      icon: Icons.currency_rupee,
                      color: Colors.red,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Additional Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Platform Overview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          'Average Revenue per Order',
                          stats.totalOrders > 0
                              ? NumberFormatter.formatCurrency(
                                  stats.totalRevenue / stats.totalOrders)
                              : '₹0.00',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Products per Seller',
                          stats.totalSellers > 0
                              ? (stats.totalProducts / stats.totalSellers)
                                  .toStringAsFixed(1)
                              : '0',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Orders per Buyer',
                          stats.totalBuyers > 0
                              ? (stats.totalOrders / stats.totalBuyers)
                                  .toStringAsFixed(1)
                              : '0',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
