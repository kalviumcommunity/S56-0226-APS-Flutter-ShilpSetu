import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/spacing.dart';
import '../../core/validators/auth_validators.dart';
import '../../providers/auth_provider.dart' as app_auth;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    final auth = context.read<app_auth.AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    // Validate email format
    if (!AuthValidators.isValidEmail(email)) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(AuthValidators.getEmailValidationError(email))),
      );
      return;
    }

    if (password.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Password is required')),
      );
      return;
    }

    try {
      final user = await auth.login(email, password);
      
      if (!mounted) return;
      
      if (user != null) {
        // AuthProvider fetches user data during login, so we can access it here
        final role = auth.userModel?.role;
        
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
        } else if (role == 'buyer') {
          Navigator.pushReplacementNamed(context, '/buyer-dashboard');
        } else if (role == 'seller') {
          Navigator.pushReplacementNamed(context, '/seller-dashboard');
        } else {
          // Fallback if role is unknown or missing (e.g. Firestore read failed)
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Offline Mode: Could not fetch role. Defaulting to Buyer Dashboard.'),
              duration: Duration(seconds: 4),
            ),
          );
          
          Navigator.pushReplacementNamed(context, '/buyer-dashboard');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      
      // Check for network errors
      String errorMessage = e.message ?? 'An error occurred. Please try again.';
      if (e.code == 'network-request-failed' || 
          errorMessage.toLowerCase().contains('network')) {
        errorMessage = '⚠️ Network Error: Cannot reach Firebase servers.\n\n'
            'Please check:\n'
            '• Emulator internet connection\n'
            '• Try restarting emulator with: emulator -dns-server 8.8.8.8\n'
            '• Or use a physical device for testing';
      }
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 6),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Check if it's a network-related error
      String errorMessage = 'An error occurred. Please try again.';
      if (e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('host lookup')) {
        errorMessage = '⚠️ Network Error: Cannot connect to servers.\n\n'
            'Emulator network issue detected. See EMULATOR_NETWORK_FIX.md for solutions.';
      }
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 6),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app_auth.AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final formWidth = constraints.maxWidth > 600 
                ? 420.0 
                : constraints.maxWidth - (AppSpacing.screenPadding * 2);

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: SizedBox(
                  width: formWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      
                      // Title
                      Text(
                        'Welcome Back',
                        style: AppTextStyles.pageTitle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      
                      // Subtitle
                      Text(
                        'Sign in to continue to ShilpSetu',
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      
                      // Form Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            CustomTextField(
                              controller: _emailCtrl,
                              hintText: 'Email address',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            CustomTextField(
                              controller: _passCtrl,
                              hintText: 'Password',
                              obscureText: true,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            auth.loading
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.mutedForestGreen,
                                    ),
                                  )
                                : CustomButton(
                                    label: 'Sign In',
                                    onPressed: _doLogin,
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      
                      // Sign up link
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          child: Text(
                            "Don't have an account? Sign up",
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primaryAccent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}