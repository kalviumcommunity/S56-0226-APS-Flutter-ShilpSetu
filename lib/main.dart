import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/buyer/buyer_dashboard.dart';
import 'screens/buyer/cart_screen.dart';
import 'screens/seller/seller_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Enable Firestore offline persistence (mobile/desktop only)
    // Web uses IndexedDB persistence automatically
    if (!kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: 100 * 1024 * 1024, // 100MB cache limit
      );
    }
  } catch (e) {
    // Log generic error without exposing internal details
    if (kDebugMode) {
      debugPrint('Firebase initialization failed');
    }
    // In production, send to crash reporting service
  }

  if (kDebugMode) {
    debugPrint('Starting app...');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => ProductProvider(),
        ),
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const LoginScreen(),
        routes: {
          '/signup': (context) => const SignupScreen(),
          '/login': (context) => const LoginScreen(),
          '/buyer-dashboard': (context) => const BuyerDashboard(),
          '/seller-dashboard': (context) => const SellerDashboard(),
          '/cart': (context) => const CartScreen(),
        },
      ),
    );
  }
}
