import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_page.dart';
import '../customer/customer_app.dart';
import '../cleaner/cleaner_app.dart';
import 'choose_login_page.dart';
import 'dart:developer' as dev;

class LoginPage extends StatefulWidget {
  final String userType;
  const LoginPage({super.key, required this.userType});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    try {
      dev.log("Attempting to sign in with email: ${_emailController.text} as ${widget.userType}");
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (userCredential.user != null) {
        dev.log("User signed in: ${userCredential.user!.uid}");
        final displayName = userCredential.user!.displayName ?? '';
        dev.log("User displayName: $displayName");
        if (displayName.startsWith(widget.userType)) {
          dev.log("User type matched: ${widget.userType}");
          // Show success alert and redirect to respective app
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Login Successful!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            if (widget.userType == "Customer") {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const CustomerApp()),
                    (route) => false,
              );
            } else if (widget.userType == "Cleaner") {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const CleanerApp()),
                    (route) => false,
              );
            }
          });
        } else {
          dev.log("User type mismatch: Expected ${widget.userType}, got ${displayName.split(' - ')[0]}");
          setState(() {
            _errorMessage = "You cannot log in as ${widget.userType} with this account.";
          });
          await _auth.signOut();
        }
      }
    } on FirebaseAuthException catch (e) {
      dev.log("FirebaseAuthException for ${widget.userType}: ${e.code} - ${e.message}");
      // Show SnackBar for all authentication failures
      dev.log("Showing invalid credentials SnackBar for ${widget.userType}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid User Email or Password", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      dev.log("Unexpected error for ${widget.userType}: $e");
      // Fallback to ensure SnackBar for any error
      dev.log("Showing fallback SnackBar for ${widget.userType}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid User Email or Password", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
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
              Text(
                "Sign In as ${widget.userType}",
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
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
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined),
                  labelText: "Email",
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
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Forgot Password?",
                  style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                onPressed: _signIn,
                child: const Text(
                  "Sign In",
                  style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignupPage(userType: widget.userType)),
                  );
                },
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    text: "Not a member yet? ",
                    style: TextStyle(color: Colors.black, fontSize: 14),
                    children: [
                      TextSpan(
                        text: "Sign Up",
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