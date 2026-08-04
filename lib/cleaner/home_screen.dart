import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {'jobsCompleted': 0, 'earnings': 0};

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      dev.log("Fetching stats for user: ${user.uid}");
      final completedJobs = await _firestore
          .collection('jobs')
          .where('cleanerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed')
          .get();

      int jobsCompleted = completedJobs.docs.length;
      double totalEarnings = completedJobs.docs.fold(0, (sum, doc) => sum + (doc.data()['totalPrice'] as num));

      setState(() {
        _stats = {
          'jobsCompleted': jobsCompleted,
          'earnings': totalEarnings,
        };
        _isLoading = false;
      });
    } catch (e) {
      dev.log("Error fetching stats: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        title: const Text(
          "Cleaner Dashboard",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: const Color(0xFFF8F6F0),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          _buildStatsCard(user),
          const SizedBox(height: 16),
          _buildWelcomeSection(),
        ],
      ),
    );
  }

  Widget _buildStatsCard(user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "This Month's Stats",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("Jobs Completed", "${_stats['jobsCompleted']}", Icons.check_circle, Colors.green),
                _buildStatItem("Earnings", "${_stats['earnings']} LKR", Icons.attach_money, Colors.black),
                StreamBuilder<QuerySnapshot>(
                  stream: user != null
                      ? FirebaseFirestore.instance
                      .collection('reviews')
                      .where('reviewedId', isEqualTo: user.uid)
                      .where('type', isEqualTo: 'customer_to_cleaner')
                      .snapshots()
                      : null,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildStatItem("Rating", "Loading...", Icons.star, Colors.amber);
                    }
                    if (snapshot.hasError) {
                      dev.log('Error fetching ratings: ${snapshot.error}');
                      return _buildStatItem("Rating", "Error", Icons.star, Colors.amber);
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildStatItem("Rating", "0.0", Icons.star, Colors.amber);
                    }

                    // Calculate average rating
                    final reviews = snapshot.data!.docs;
                    double totalRating = 0;
                    for (var review in reviews) {
                      final data = review.data() as Map<String, dynamic>;
                      totalRating += (data['rating'] as num).toDouble();
                    }
                    final averageRating = totalRating / reviews.length;

                    return _buildStatItem("Rating", averageRating.toStringAsFixed(1), Icons.star, Colors.amber);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color iconColor) {
    return Column(
      children: [
        Icon(icon, size: 30, color: iconColor),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome, Cleaner!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            const Text(
              "Find new cleaning jobs in the 'Find Jobs' section and track your accepted jobs in 'Ongoing Jobs'.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/find_jobs'); // Adjust route as per your app
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Browse Jobs"),
            ),
          ],
        ),
      ),
    );
  }
}