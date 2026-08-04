import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mobile_new/firebase_options.dart';
import 'login/choose_login_page.dart';
import 'cleaner/find_jobs_screen.dart';
import 'cleaner/ongoing_jobs.dart';
import 'dart:developer' as dev;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isFirebaseInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      dev.log("Firebase initialized successfully");
      setState(() => _isFirebaseInitialized = true);
    } catch (e) {
      dev.log("Firebase initialization failed: $e");
      setState(() => _errorMessage = "Failed to initialize Firebase: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (!_isFirebaseInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CleanZone',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8F6F0),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.grey),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black, width: 2),
          ),
          prefixIconColor: Colors.grey,
        ),
      ),
      home: const ChooseLoginPage(),
      routes: {
        '/find_jobs': (context) => const FindJobsScreen(),
        '/ongoing_jobs': (context) => const OngoingJobsScreen(),
      },
    );
  }
}