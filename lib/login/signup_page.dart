import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../customer/customer_app.dart';
import '../cleaner/cleaner_app.dart';
import 'login_page.dart';
import 'dart:developer' as dev;

class SignupPage extends StatefulWidget {
  final String userType;
  const SignupPage({super.key, required this.userType});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    dev.log("Starting sign-up for ${widget.userType}");
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      dev.log("Validation failed: Invalid email");
      setState(() {
        _errorMessage = "Please enter a valid email address";
      });
      return;
    }
    if (_usernameController.text.isEmpty) {
      dev.log("Validation failed: Empty username");
      setState(() {
        _errorMessage = "Please enter a username";
      });
      return;
    }
    if (_passwordController.text.length < 6) {
      dev.log("Validation failed: Password too short");
      setState(() {
        _errorMessage = "Password must be at least 6 characters";
      });
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      dev.log("Validation failed: Passwords do not match");
      setState(() {
        _errorMessage = "Passwords do not match";
      });
      return;
    }

    try {
      dev.log("Attempting to sign up with email: ${_emailController.text}");
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (userCredential.user != null) {
        dev.log("User created: ${userCredential.user!.uid}");
        await userCredential.user!.updateDisplayName('${widget.userType} - ${_usernameController.text}');

        // Store user data in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': _emailController.text.trim(),
          'username': _usernameController.text.trim(),
          'userType': widget.userType,
          'phone': '', // Initialize as empty, to be updated in edit profile
          'location': '', // Initialize as empty, to be updated in edit profile
        });
        dev.log("User data stored in Firestore for UID: ${userCredential.user!.uid}");

        // Show success alert and redirect to login page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sign-up Successful!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginPage(userType: widget.userType)),
                (route) => false,
          );
        });
      }
    } on FirebaseAuthException catch (e) {
      dev.log("FirebaseAuthException: ${e.code} - ${e.message}");
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      dev.log("Unexpected error: $e");
      setState(() {
        _errorMessage = "An unexpected error occurred: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    "assets/logo.png",
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text("Image failed to load");
                    },
                  ),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Create a new account",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined),
                  labelText: "Email",
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                  labelText: "Username",
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  labelText: "Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  labelText: "Confirm Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                onPressed: _signUp,
                child: const Text(
                  "Sign Up",
                  style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    text: "Already a member? ",
                    style: TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: "Sign In",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}