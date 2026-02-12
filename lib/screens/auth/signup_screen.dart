import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/validators/auth_validators.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  String? _selectedRole;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final auth = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    final name = _nameCtrl.text.trim();
    final role = _selectedRole;

    if (name.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    if (role == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please select a role (Buyer or Seller)')),
      );
      return;
    }

    // Validate email format
    if (!AuthValidators.isValidEmail(email)) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(AuthValidators.getEmailValidationError(email))),
      );
      return;
    }

    // Validate password strength
    if (!AuthValidators.isValidPassword(password)) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content:
                Text(AuthValidators.getPasswordValidationError(password))),
      );
      return;
    }

    try {
      await auth.signup(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Account created successfully')),
      );

      // Navigate directly without popping first
      if (role == 'buyer') {
        Navigator.pushReplacementNamed(context, '/buyer-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/seller-dashboard');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // Use the generic error message from auth provider
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(e.message ?? 'An error occurred. Please try again.')),
      );
    } catch (e) {
      if (!mounted) return;
      // Never expose full exception details to user
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final formWidth =
              constraints.maxWidth > 600 ? 420.0 : constraints.maxWidth * 0.9;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: SizedBox(
                width: formWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Create your shop',
                        style: AppTextStyles.title),
                    const SizedBox(height: 8),
                    Text(
                      'Get your catalog online and reach buyers in your neighbourhood.',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: _nameCtrl,
                            hintText: 'Full Name',
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _emailCtrl,
                            hintText: 'Email',
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _passCtrl,
                            hintText: 'Password',
                            obscureText: true,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'I am a:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildRoleCard(
                                  label: 'Buyer',
                                  icon: Icons.shopping_bag_outlined,
                                  isSelected: _selectedRole == 'buyer',
                                  onTap: () => setState(() => _selectedRole = 'buyer'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildRoleCard(
                                  label: 'Seller',
                                  icon: Icons.storefront_outlined,
                                  isSelected: _selectedRole == 'seller',
                                  onTap: () => setState(() => _selectedRole = 'seller'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          auth.loading
                              ? const CircularProgressIndicator()
                              : CustomButton(
                                  label: 'Create Account',
                                  onPressed: _createAccount,
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildRoleCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.muted,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}