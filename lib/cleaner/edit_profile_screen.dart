import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

class EditProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String location;

  const EditProfileScreen({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController locationController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    emailController = TextEditingController(text: widget.email);
    phoneController = TextEditingController(text: widget.phone);
    locationController = TextEditingController(text: widget.location);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        dev.log("Saving profile for UID: ${user.uid}");
        await _firestore.collection('users').doc(user.uid).update({
          'phone': phoneController.text.trim(),
          'location': locationController.text.trim(),
        });
        dev.log("Profile updated successfully");
        Navigator.pop(context, {
          'name': nameController.text,
          'email': emailController.text,
          'phone': phoneController.text,
          'location': locationController.text,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Saved!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        dev.log("Error saving profile: $e");
        setState(() {
          _errorMessage = "Failed to save profile: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange[400],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.orange,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 30),
            _buildEditField("Name", Icons.person, nameController, enabled: false),
            const SizedBox(height: 16),
            _buildEditField("Email", Icons.email, emailController, enabled: false),
            const SizedBox(height: 16),
            _buildEditField("Phone", Icons.phone, phoneController),
            const SizedBox(height: 16),
            _buildEditField("Location", Icons.location_on, locationController),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                elevation: 0,
              ),
              child: const Text(
                "Save Changes",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(String label, IconData icon, TextEditingController controller, {bool enabled = true}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.orange, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
    );
  }
}