import 'package:flutter/material.dart';
import 'package:food_order_system/pages/welcome_page.dart';

void main() {
  runApp(const FoodOrderApp());
}

class FoodOrderApp extends StatelessWidget {
  const FoodOrderApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food Ordering App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const WelcomePage(),
    );
  }
}
