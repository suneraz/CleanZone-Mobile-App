import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';
import '../login/choose_login_page.dart';
import 'dart:developer' as dev;

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key, required String userType});

  @override
  _CustomerProfileScreenState createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String name = '';
  String email = '';
  String phone = '';
  String location = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = _auth.currentUser;
    if (user != null) {
      dev.log("Fetching profile data for UID: ${user.uid}");
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          name = doc.data()?['username'] ?? 'Unknown';
          email = doc.data()?['email'] ?? 'Unknown';
          phone = doc.data()?['phone'] ?? '';
          location = doc.data()?['location'] ?? '';
        });
        dev.log("Profile data loaded: $name, $email, $phone, $location");
      } else {
        dev.log("No profile data found for UID: ${user.uid}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildPersonalInfo(),
          const SizedBox(height: 16),
          _buildSettingsSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: Colors.orange,
          child: Icon(Icons.person, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const Text(
          "Customer",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPersonalInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Personal Information",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email, email),
            _buildInfoRow(Icons.phone, phone.isEmpty ? "Not set" : phone),
            _buildInfoRow(Icons.location_on, location.isEmpty ? "Not set" : location),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.orange),
            title: const Text("Edit Profile"),
            onTap: _navigateToEditProfile,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout"),
            onTap: () async {
              await _auth.signOut();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Logout Successful!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
              Future.delayed(const Duration(milliseconds: 500), () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const ChooseLoginPage()),
                      (route) => false,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerEditProfileScreen(
          name: name,
          email: email,
          phone: phone,
          location: location,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        phone = result['phone'];
        location = result['location'];
      });
    }
  }
}