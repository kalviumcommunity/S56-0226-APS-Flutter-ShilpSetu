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

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.card,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: AppColors.primaryAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Success',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.card,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: AppColors.primaryAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createAccount() async {
    final auth = context.read<AuthProvider>();

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    final name = _nameCtrl.text.trim();
    final role = _selectedRole;

    if (name.isEmpty) {
      _showErrorDialog('Name Required', 'Please enter your full name to continue');
      return;
    }

    if (role == null) {
      _showErrorDialog('Role Required', 'Please select whether you are a Buyer or Seller');
      return;
    }

    // Validate email format
    if (!AuthValidators.isValidEmail(email)) {
      _showErrorDialog('Invalid Email', AuthValidators.getEmailValidationError(email));
      return;
    }

    // Validate password strength
    if (!AuthValidators.isValidPassword(password)) {
      _showErrorDialog('Weak Password', AuthValidators.getPasswordValidationError(password));
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
      
      _showSuccessDialog('Your account has been created successfully!\n\nTapping OK will take you to your dashboard.');

      // Navigate after success
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          if (role == 'buyer') {
            Navigator.pushReplacementNamed(context, '/buyer-dashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/seller-dashboard');
          }
        }
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      
      String errorTitle = 'Signup Failed';
      String errorMessage = e.message ?? 'An error occurred. Please try again.';
      
      // Check for specific error codes and provide better messages
      if (e.code == 'email-already-in-use') {
        errorTitle = 'Email Already Registered';
        errorMessage = 'This email is already registered.\n\nPlease use a different email or try logging in.';
      } else if (e.code == 'invalid-email') {
        errorTitle = 'Invalid Email';
        errorMessage = 'The email address is not valid.\n\nPlease check and try again.';
      } else if (e.code == 'weak-password') {
        errorTitle = 'Weak Password';
        errorMessage = 'The password is too weak.\n\nPlease use a password with at least 8 characters.';
      } else if (e.code == 'operation-not-allowed') {
        errorTitle = 'Signup Disabled';
        errorMessage = 'Signup is currently disabled.\n\nPlease try again later.';
      } else if (e.code == 'network-request-failed' || 
          errorMessage.toLowerCase().contains('network')) {
        errorTitle = 'Network Error';
        errorMessage = 'Cannot connect to the server.\n\nPlease check your internet connection and try again.';
      }
      
      _showErrorDialog(errorTitle, errorMessage);
    } catch (e) {
      if (!mounted) return;
      
      String errorTitle = 'Error';
      String errorMessage = 'An unexpected error occurred.\n\nPlease try again.';
      
      if (e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        errorTitle = 'Network Error';
        errorMessage = 'Cannot connect to the server.\n\nPlease check your internet connection.';
      }
      
      _showErrorDialog(errorTitle, errorMessage);
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