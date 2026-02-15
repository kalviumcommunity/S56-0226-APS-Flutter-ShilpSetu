import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/buyer/buyer_dashboard.dart';
import 'screens/buyer/cart_screen.dart';
import 'screens/seller/seller_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';

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

  // Pre-cache Google Fonts to avoid runtime loading issues
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.playfairDisplay(),
      GoogleFonts.inter(),
    ]);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Google Fonts pre-caching failed, will use fallback fonts');
    }
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
        theme: _buildAppTheme(),
        home: const LoginScreen(),
        routes: {
          '/signup': (context) => const SignupScreen(),
          '/login': (context) => const LoginScreen(),
          '/buyer-dashboard': (context) => const BuyerDashboard(),
          '/seller-dashboard': (context) => const SellerDashboard(),
          '/admin-dashboard': (context) => const AdminDashboard(),
          '/cart': (context) => const CartScreen(),
        },
      ),
    );
  }

  ThemeData _buildAppTheme() {
    return ThemeData(
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme(),
      scaffoldBackgroundColor: const Color(0xFFF6F1E8), // Soft Warm Beige
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2F5D50), // Muted Forest Green
        secondary: Color(0xFFDCE5DD), // Light Sage Tint
        surface: Color(0xFFFFFFFF), // White
        error: Color(0xFFC96C5B), // Muted Terracotta
        onPrimary: Colors.white,
        onSecondary: Color(0xFF2E2A26), // Deep Charcoal Brown
        onSurface: Color(0xFF2E2A26), // Deep Charcoal Brown
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF6F1E8), // Soft Warm Beige
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2E2A26)), // Deep Charcoal Brown
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF2E2A26), // Deep Charcoal Brown
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF), // White
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2F5D50), // Muted Forest Green
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFFFF), // White
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD9D0C7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD9D0C7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2F5D50), width: 2),
        ),
      ),
    );
  }
}
