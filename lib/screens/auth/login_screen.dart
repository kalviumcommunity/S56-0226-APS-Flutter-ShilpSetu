import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
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
      await auth.login(email, password);

      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Logged in successfully')),
      );
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
    final auth = context.watch<app_auth.AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Login'),
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
                    Text('Artisan Storefront',
                        style: AppTextStyles.title),
                    const SizedBox(height: 8),
                    Text(
                      'A simple digital storefront for local makers — manage products and orders effortlessly.',
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
                          auth.loading
                              ? const CircularProgressIndicator()
                              : CustomButton(
                                  label: 'Login',
                                  onPressed: _doLogin,
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        child:
                            const Text("Don't have an account? Sign up"),
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
}