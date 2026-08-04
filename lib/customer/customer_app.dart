import 'package:flutter/material.dart';
import 'customer_home.dart';

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CustomerHome(), // Removed `const` since CustomerHome is Stateful
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: const Color(0xFFF8F6F0),
      ),
    );
  }
}