import 'package:flutter/material.dart';
import 'cleaner_home.dart';

class CleanerApp extends StatelessWidget {
  const CleanerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const CleanerHome(),
      theme: ThemeData(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: const Color(0xFFF8F6F0),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.grey),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}