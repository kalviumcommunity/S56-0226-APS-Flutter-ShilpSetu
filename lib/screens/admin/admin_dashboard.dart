import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/colors.dart';
import 'users_tab.dart';
import 'products_tab.dart';
import 'orders_tab.dart';
import 'reviews_tab.dart';
import 'platform_analytics_tab.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.userModel?.name ?? 'Admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Panel',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              userName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.text,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabs: const [
            Tab(
              icon: Icon(Icons.people),
              text: 'Users',
            ),
            Tab(
              icon: Icon(Icons.inventory),
              text: 'Products',
            ),
            Tab(
              icon: Icon(Icons.shopping_bag),
              text: 'Orders',
            ),
            Tab(
              icon: Icon(Icons.star),
              text: 'Reviews',
            ),
            Tab(
              icon: Icon(Icons.analytics),
              text: 'Analytics',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          UsersTab(),
          ProductsTab(),
          OrdersTab(),
          ReviewsTab(),
          PlatformAnalyticsTab(),
        ],
      ),
    );
  }
}
