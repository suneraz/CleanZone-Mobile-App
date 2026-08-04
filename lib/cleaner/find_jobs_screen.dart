import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import 'ongoing_jobs.dart';

class FindJobsScreen extends StatefulWidget {
  const FindJobsScreen({super.key});

  @override
  _FindJobsScreenState createState() => _FindJobsScreenState();
}

class _FindJobsScreenState extends State<FindJobsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _availableJobs = [];
  bool _isLoading = true;
  String _username = 'User';

  @override
  void initState() {
    super.initState();
    _fetchUsername();
    _fetchAvailableJobs();
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

  Future<void> _fetchAvailableJobs() async {
    final user = _auth.currentUser;
    dev.log("Cleaner UID: ${user?.uid ?? 'Not logged in'}");
    if (user == null) {
      dev.log("No user logged in");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please log in")));
      setState(() => _isLoading = false);
      return;
    }

    try {
      dev.log("Fetching available jobs for cleaner: ${user.uid}");
      final snapshot = await _firestore
          .collection('jobs')
          .where('status', isEqualTo: 'available')
          .get();

      List<Map<String, dynamic>> jobs = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        // Fetch customer username
        final customerId = data['customerId'] as String?;
        String customerName = 'Unknown';
        if (customerId != null) {
          final customerDoc = await _firestore.collection('users').doc(customerId).get();
          if (customerDoc.exists) {
            customerName = customerDoc.data()?['username'] ?? 'Unknown';
          }
        }
        data['customerName'] = customerName;
        jobs.add(data);
      }

      setState(() {
        _availableJobs = jobs;
        _isLoading = false;
      });
      dev.log("Fetched ${_availableJobs.length} available jobs: ${_availableJobs.map((j) => j['id']).join(', ')}");
    } catch (e) {
      dev.log("Error fetching available jobs: $e");
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to fetch jobs: $e")));
    }
  }

  Future<void> _acceptJob(String jobId) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You must be logged in")));
      return;
    }

    try {
      dev.log("Accepting job: $jobId by cleaner: ${user.uid}");
      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'ongoing',
        'cleanerId': user.uid,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Job Accepted!"), backgroundColor: Colors.green),
      );
      await _fetchAvailableJobs();
    } catch (e) {
      dev.log("Error accepting job: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to accept job: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Find Jobs, $_username",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: const Color(0xFFF8F6F0),
      ),
      backgroundColor: const Color(0xFFF8F6F0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availableJobs.isEmpty
          ? const Center(child: Text("No available jobs"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _availableJobs.length,
        itemBuilder: (context, index) {
          final job = _availableJobs[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        job['jobType'] ?? 'Cleaning Service',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "LKR ${job['totalPrice']?.toString() ?? 'N/A'}",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Customer: ${job['customerName']}",
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Date: ${job['date']?.split('T')[0] ?? 'Not set'}",
                    style: const TextStyle(color: Colors.black),
                  ),
                  Text(
                    "Time: ${job['time'] ?? 'Not set'}",
                    style: const TextStyle(color: Colors.black),
                  ),
                  Text(
                    "Address: ${job['address'] ?? 'Not specified'}",
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "House Details:",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Text(
                    "Rooms: ${job['numberOfRooms']?.toString() ?? 'Not specified'}",
                    style: const TextStyle(color: Colors.black),
                  ),
                  Text(
                    "Bathrooms: ${job['numberOfBathrooms']?.toString() ?? 'Not specified'}",
                    style: const TextStyle(color: Colors.black),
                  ),
                  Text(
                    "Flooring: ${job['flooringType'] ?? 'Not applicable'}",
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Images:",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  SizedBox(
                    height: 100,
                    child: job['houseImages'] != null && (job['houseImages'] as List).isNotEmpty
                        ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: (job['houseImages'] as List).length,
                      itemBuilder: (context, index) {
                        final imagePath = job['houseImages'][index];
                        return imagePath.isNotEmpty
                            ? Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              imagePath,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Text("Image unavailable",
                                    style: TextStyle(color: Colors.black));
                              },
                            ),
                          ),
                        )
                            : const SizedBox.shrink();
                      },
                    )
                        : const Text("No images uploaded", style: TextStyle(color: Colors.black)),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: () => _acceptJob(job['id']),
                      child: const Text(
                        "Accept Job",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchAvailableJobs,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}