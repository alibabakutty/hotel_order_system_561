import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:food_order_system/authentication/auth_service.dart';
import 'package:food_order_system/firebase_options.dart';
import 'package:food_order_system/pages/admin_login.dart';
import 'package:food_order_system/pages/cda_page.dart';
import 'package:food_order_system/pages/admin_dashboard.dart';
import 'package:food_order_system/pages/display_fetch_page.dart';
import 'package:food_order_system/pages/item_master.dart';
import 'package:food_order_system/pages/order_list.dart';
import 'package:food_order_system/pages/order_master.dart';
import 'package:food_order_system/pages/supplier_login.dart';
import 'package:food_order_system/pages/supplier_master.dart';
import 'package:food_order_system/pages/table_master.dart';
import 'package:food_order_system/pages/update_fetch_page.dart';
import 'package:food_order_system/pages/welcome_page.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void main() async {
  // This line mandatory after conect with firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Run heavy initialization in a separate isolate
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
  ]);
  runApp(
    MultiProvider(
      providers: [Provider<AuthService>(create: (_) => AuthService())],
      child: const FoodOrderApp(),
    ),
  );
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const WelcomePage(),
      routes: [
        GoRoute(
          path: '/admin_login',
          builder: (context, state) => const AdminLogin(),
        ),
        GoRoute(
          path: '/supplier_login',
          builder: (context, state) => const SupplierLogin(),
        ),
        GoRoute(
          path: '/admin_dashboard',
          builder: (context, state) => AdminDashboard(
            authService: Provider.of<AuthService>(context, listen: false),
          ),
        ),
        GoRoute(
          path: '/cda_page',
          builder: (context, state) {
            final masterType = state.extra as String;
            return CdaPage(masterType: masterType);
          },
        ),
        GoRoute(
          path: '/display_fetch',
          builder: (context, state) {
            final masterType = state.extra as String;
            return DisplayFetchPage(masterType: masterType);
          },
        ),
        GoRoute(
          path: '/update_fetch',
          builder: (context, state) {
            final masterType = state.extra as String;
            return UpdateFetchPage(masterType: masterType);
          },
        ),
        GoRoute(
          path: '/item_master',
          builder: (context, state) {
            // Extract arguments from state.extra
            final args = state.extra as Map<String, dynamic>? ?? {};
            return ItemMaster(
              itemName: args['itemName'],
              isDisplayMode: args['isDisplayMode'] ?? false,
            );
          },
        ),
        GoRoute(
          path: '/supplier_master',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>? ?? {};
            return SupplierMaster(
              supplierName: args['supplierName'],
              isDisplayMode: args['isDisplayMode'] ?? false,
            );
          },
        ),
        GoRoute(
          path: '/table_master',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>? ?? {};
            return TableMaster(
              tableNumber: args['tableNumber'],
              isDisplayMode: args['isDisplayMode'] ?? false,
            );
          },
        ),
        GoRoute(
          path: '/order_master',
          builder: (context, state) => const OrderMaster(),
        ),
        GoRoute(
          path: '/order_list',
          builder: (context, state) => const OrderList(),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('Error: ${state.error}'))),
);

class FoodOrderApp extends StatelessWidget {
  const FoodOrderApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Hotel Order Management App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routerConfig: _router,
    );
  }
}
