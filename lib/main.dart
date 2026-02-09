import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/buyer/buyer_dashboard.dart';
import 'screens/seller/seller_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('DEBUG: Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('DEBUG: Firebase initialized successfully');
    
    // Enable Firestore offline persistence (mobile/desktop only)
    // Web uses IndexedDB persistence automatically
    if (!kIsWeb) {
      print('DEBUG: Enabling Firestore persistence...');
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      print('DEBUG: Firestore persistence enabled');
    }
  } catch (e, stackTrace) {
    // Log initialization error and continue
    debugPrint('Firebase initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  print('DEBUG: Starting app...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building MyApp widget');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const LoginScreen(),
        routes: {
          '/signup': (context) => const SignupScreen(),
          '/buyer-dashboard': (context) => const BuyerDashboard(),
          '/seller-dashboard': (context) => const SellerDashboard(),
        },
      ),
    );
  }
}
