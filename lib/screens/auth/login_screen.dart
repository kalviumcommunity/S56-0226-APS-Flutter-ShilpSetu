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

  Future<void> _doLogin() async {
    final auth = context.read<app_auth.AuthProvider>();

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    // Validate email format
    if (!AuthValidators.isValidEmail(email)) {
      _showErrorDialog('Invalid Email', AuthValidators.getEmailValidationError(email));
      return;
    }

    if (password.isEmpty) {
      _showErrorDialog('Password Required', 'Please enter your password to continue');
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
          _showErrorDialog(
            'Role Not Found',
            'Could not fetch your role. Defaulting to Buyer Dashboard.',
          );
          Navigator.pushReplacementNamed(context, '/buyer-dashboard');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      
      String errorTitle = 'Login Failed';
      String errorMessage = e.message ?? 'An error occurred. Please try again.';
      
      // Check for specific error codes and provide better messages
      if (e.code == 'user-not-found') {
        errorTitle = 'Account Not Found';
        errorMessage = 'No account found with this email address.\n\nPlease sign up to create an account.';
      } else if (e.code == 'wrong-password') {
        errorTitle = 'Invalid Password';
        errorMessage = 'The password you entered is incorrect.\n\nPlease try again.';
      } else if (e.code == 'invalid-email') {
        errorTitle = 'Invalid Email';
        errorMessage = 'The email address is not valid.\n\nPlease check and try again.';
      } else if (e.code == 'user-disabled') {
        errorTitle = 'Account Disabled';
        errorMessage = 'This account has been disabled.\n\nPlease contact support for help.';
      } else if (e.code == 'too-many-requests') {
        errorTitle = 'Too Many Login Attempts';
        errorMessage = 'Too many failed login attempts.\n\nPlease try again later.';
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
          e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('host lookup')) {
        errorTitle = 'Network Error';
        errorMessage = 'Cannot connect to the server.\n\nPlease check your internet connection.';
      }
      
      _showErrorDialog(errorTitle, errorMessage);
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