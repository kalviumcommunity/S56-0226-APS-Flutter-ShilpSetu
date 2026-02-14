import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class PaymentSelectionScreen extends StatefulWidget {
  final double totalAmount;

  const PaymentSelectionScreen({
    super.key,
    required this.totalAmount,
  });

  @override
  State<PaymentSelectionScreen> createState() => _PaymentSelectionScreenState();
}

class _PaymentSelectionScreenState extends State<PaymentSelectionScreen> {
  String? _selectedPaymentMethod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Payment Method'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Amount Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.currency_rupee,
                      color: Colors.white,
                      size: 28,
                    ),
                    Text(
                      widget.totalAmount.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Payment Methods
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Choose Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),

                // Cash on Delivery
                _PaymentMethodCard(
                  icon: Icons.money,
                  title: 'Cash on Delivery',
                  subtitle: 'Pay when you receive your order',
                  value: 'cod',
                  selectedValue: _selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  },
                  enabled: true,
                ),

                const SizedBox(height: 12),

                // Razorpay (Disabled)
                _PaymentMethodCard(
                  icon: Icons.payment,
                  title: 'Razorpay',
                  subtitle: 'Pay online (Coming Soon)',
                  value: 'razorpay',
                  selectedValue: _selectedPaymentMethod,
                  onChanged: null,
                  enabled: false,
                ),

                const SizedBox(height: 12),

                // UPI (Disabled)
                _PaymentMethodCard(
                  icon: Icons.account_balance,
                  title: 'UPI',
                  subtitle: 'Pay via UPI (Coming Soon)',
                  value: 'upi',
                  selectedValue: _selectedPaymentMethod,
                  onChanged: null,
                  enabled: false,
                ),

                const SizedBox(height: 12),

                // Card Payment (Disabled)
                _PaymentMethodCard(
                  icon: Icons.credit_card,
                  title: 'Credit/Debit Card',
                  subtitle: 'Pay via card (Coming Soon)',
                  value: 'card',
                  selectedValue: _selectedPaymentMethod,
                  onChanged: null,
                  enabled: false,
                ),
              ],
            ),
          ),

          // Confirm Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedPaymentMethod == null
                    ? null
                    : () {
                        final paymentData = <String, String>{
                          'paymentMethod': _selectedPaymentMethod!,
                          'paymentStatus': 'pending',
                        };
                        // Use post-frame callback to avoid navigator lock issues
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            Navigator.pop(context, paymentData);
                          }
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Confirm Payment Method',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String? selectedValue;
  final ValueChanged<String?>? onChanged;
  final bool enabled;

  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.selectedValue,
    required this.onChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedValue == value;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? const BorderSide(color: AppColors.primary, width: 2)
              : BorderSide.none,
        ),
        child: RadioListTile<String>(
          value: value,
          groupValue: selectedValue,
          onChanged: enabled ? onChanged : null,
          activeColor: AppColors.primary,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: enabled ? AppColors.primary : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: enabled ? Colors.black : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: enabled ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
