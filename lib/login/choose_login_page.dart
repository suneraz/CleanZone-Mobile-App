import 'package:flutter/material.dart';
import 'login_page.dart';
import '../customer/customer_app.dart';
import '../cleaner/cleaner_app.dart';

class ChooseLoginPage extends StatelessWidget {
  const ChooseLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey, width: 1), // Rounded corners
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26, // Shadow color
                        blurRadius: 10, // Softness of shadow
                        spreadRadius: 2, // Spread of shadow
                        offset: Offset(0, 4), // Position of shadow
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20), // Ensures the image follows rounded corners
                    child: Image.asset(
                      "assets/firstpage.jpg",
                      height: 300, // Keeping the original height from your Center widget
                      fit: BoxFit.cover, // Ensures the image covers the space properly
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              const Text(
                "Welcome to Cleanzone",
                style: TextStyle(
                  fontFamily: "Roboto",
                  fontSize: 30, // Bigger for emphasis
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 1, // Adds spacing for a clean, premium feel
                  shadows: [
                    Shadow(
                      color: Colors.grey, // Subtle shadow effect
                      offset: Offset(3, 3),
                      blurRadius: 5,
                    ),
                  ],
                ),
                textAlign: TextAlign.center, // Centers the text
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(userType: "Customer"),
                    ),
                  );
                },
                child: const Text(
                  "Login as Customer",
                  style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(userType: "Cleaner"),
                    ),
                  );
                },
                child: const Text(
                  "Login as Cleaner",
                  style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}