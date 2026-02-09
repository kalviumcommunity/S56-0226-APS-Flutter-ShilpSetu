import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class BuyerDashboard extends StatelessWidget {
  const BuyerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch for changes in user data
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Buyer Dashboard'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.text,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome, ${user?.name ?? "Buyer"}!',
              style: AppTextStyles.title,
            ),
            const SizedBox(height: 8),
            Text(
              'Browse products and manage your orders.',
              style: AppTextStyles.subtitle,
            ),
          ],
        ),
      ),
    );
  }
}
