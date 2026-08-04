import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

class OngoingJobsScreen extends StatefulWidget {
  const OngoingJobsScreen({super.key});

  @override
  State<OngoingJobsScreen> createState() => _OngoingJobsScreenState();
}

class _OngoingJobsScreenState extends State<OngoingJobsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _pendingJobs = [];
  List<Map<String, dynamic>> _ongoingJobs = [];
  bool _isLoading = true;
  String _username = 'User';

  @override
  void initState() {
    super.initState();
    _fetchUsername();
    _fetchJobs();
  }

  Future<void> _fetchUsername() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _username = doc.data()?['username'] ?? 'User';
          });
          dev.log("Username fetched: $_username");
        }
      } catch (e) {
        dev.log("Error fetching username: $e");
      }
    }
  }

  Future<void> _fetchJobs() async {
    final user = _auth.currentUser;
    if (user == null) {
      dev.log("No user logged in");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      dev.log("Fetching jobs for customer: ${user.uid}");
      // Fetch pending jobs
      final pendingSnapshot = await _firestore
          .collection('jobs')
          .where('customerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'available')
          .get();

      List<Map<String, dynamic>> pendingJobs = [];
      for (var doc in pendingSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        pendingJobs.add(data);
      }

      // Fetch ongoing jobs and cleaner usernames
      final ongoingSnapshot = await _firestore
          .collection('jobs')
          .where('customerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'ongoing')
          .get();

      List<Map<String, dynamic>> ongoingJobs = [];
      for (var doc in ongoingSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        // Fetch cleaner username
        final cleanerId = data['cleanerId'] as String?;
        String cleanerName = 'Not Assigned';
        if (cleanerId != null) {
          final cleanerDoc = await _firestore.collection('users').doc(cleanerId).get();
          if (cleanerDoc.exists) {
            cleanerName = cleanerDoc.data()?['username'] ?? 'Unknown';
          }
        }
        data['cleanerName'] = cleanerName;
        ongoingJobs.add(data);
      }

      setState(() {
        _pendingJobs = pendingJobs;
        _ongoingJobs = ongoingJobs;
        _isLoading = false;
      });
      dev.log("Fetched ${_pendingJobs.length} pending and ${_ongoingJobs.length} ongoing jobs");
    } catch (e) {
      dev.log("Error fetching jobs: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Cleaning Services, $_username",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: const Color(0xFFF8F6F0),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : (_pendingJobs.isEmpty && _ongoingJobs.isEmpty)
          ? _buildEmptyState()
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_pendingJobs.isNotEmpty) ...[
            const Text(
              "Pending Jobs",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._pendingJobs.map((job) => _buildJobCard(job, isPending: true)),
            const SizedBox(height: 16),
          ],
          if (_ongoingJobs.isNotEmpty) ...[
            const Text(
              "Ongoing Services",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._ongoingJobs.map((job) => _buildJobCard(job, isPending: false)),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchJobs,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job, {required bool isPending}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  job['jobType'] ?? 'Cleaning Service',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending ? Colors.grey : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPending ? 'Pending' : 'In Progress',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.person, 'Cleaner: ${isPending ? "Not Assigned" : job['cleanerName'] ?? "Unknown"}'),
            _buildInfoRow(Icons.calendar_today, '${job['date'].split('T')[0]} at ${job['time']}'),
            _buildInfoRow(Icons.attach_money, '${job['totalPrice']} LKR'),
            const SizedBox(height: 16),
            if (!isPending)
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to cleaner details or chat (future implementation)
                },
                icon: const Icon(Icons.message),
                label: const Text('Contact Cleaner'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cleaning_services_outlined, size: 100, color: Colors.orange[200]),
          const SizedBox(height: 16),
          const Text(
            "No Jobs Posted Yet",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            "Your posted and ongoing cleaning services will appear here",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}