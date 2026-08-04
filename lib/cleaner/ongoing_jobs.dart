import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

class OngoingJobsScreen extends StatefulWidget {
  const OngoingJobsScreen({super.key});

  @override
  _OngoingJobsScreenState createState() => _OngoingJobsScreenState();
}

class _OngoingJobsScreenState extends State<OngoingJobsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _ongoingJobs = [];
  bool _isLoading = true;
  String _username = 'User';

  @override
  void initState() {
    super.initState();
    _fetchUsername();
    _fetchOngoingJobs();
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

  Future<void> _fetchOngoingJobs() async {
    final user = _auth.currentUser;
    if (user == null) {
      dev.log("No user logged in");
      setState(() => _isLoading = false);
      return;
    }

    try {
      dev.log("Fetching ongoing jobs for cleaner: ${user.uid}");
      final snapshot = await _firestore
          .collection('jobs')
          .where('cleanerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'ongoing')
          .get();

      List<Map<String, dynamic>> jobs = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;

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
        _ongoingJobs = jobs;
        _isLoading = false;
      });
      dev.log("Fetched ${_ongoingJobs.length} ongoing jobs");
    } catch (e) {
      dev.log("Error fetching ongoing jobs: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendNotificationToCustomer(String customerId, String jobType, String jobId, {bool isReview = false, int? rating, String? comment}) async {
    try {
      final message = isReview
          ? 'The cleaner gave you a $rating-star review: "$comment"'
          : 'Your $jobType has been completed by the cleaner.';
      await _firestore.collection('users').doc(customerId).collection('notifications').add({
        'title': isReview ? 'New Review Received' : 'Job Completed',
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'jobId': jobId,
        'userId': customerId, // Add required userId field
      });
      dev.log("Notification sent to customer: $customerId - ${isReview ? 'Review' : 'Job Completed'}");
    } catch (e) {
      dev.log("Error sending notification to customer: $e", stackTrace: StackTrace.current);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send notification: $e")),
      );
    }
  }

  Future<void> _addCleanerReviewForCustomer(String jobId) async {
    final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
    final jobData = jobDoc.data()!;
    final customerId = jobData['customerId'] as String;

    final ratingController = TextEditingController();
    final commentController = TextEditingController();

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Review Customer"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ratingController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Rating (1-5)"),
            ),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(labelText: "Comment"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final rating = int.tryParse(ratingController.text) ?? 0;
              if (rating < 1 || rating > 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Rating must be between 1 and 5")),
                );
                return;
              }
              try {
                dev.log("Submitting review for customer: $customerId by cleaner: ${_auth.currentUser!.uid}");
                final reviewDoc = await _firestore.collection('reviews').add({
                  'reviewerId': _auth.currentUser!.uid,
                  'reviewedId': customerId,
                  'rating': rating,
                  'comment': commentController.text,
                  'timestamp': FieldValue.serverTimestamp(),
                  'type': 'cleaner_to_customer',
                  'jobId': jobId,
                  'reviewerName': _username,
                });
                dev.log("Review submitted successfully with ID: ${reviewDoc.id}");

                await _sendNotificationToCustomer(
                  customerId,
                  jobData['jobType'] as String,
                  jobId,
                  isReview: true,
                  rating: rating,
                  comment: commentController.text,
                );

                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Review submitted!"), backgroundColor: Colors.green),
                );
              } catch (e) {
                dev.log("Error submitting review: $e", stackTrace: StackTrace.current);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Failed to submit review: $e")),
                );
              }
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  Future<void> _completeJob(String jobId) async {
    try {
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      final jobData = jobDoc.data()!;
      final customerId = jobData['customerId'] as String;
      final jobType = jobData['jobType'] as String;

      await _firestore.collection('jobs').doc(jobId).update({'status': 'completed'});
      dev.log("Job $jobId marked as completed");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Job Completed!"), backgroundColor: Colors.green),
      );

      await _sendNotificationToCustomer(customerId, jobType, jobId);
      await _addCleanerReviewForCustomer(jobId);
      await _fetchOngoingJobs();
    } catch (e) {
      dev.log("Error completing job: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to complete job: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Ongoing Jobs, $_username",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: const Color(0xFFF8F6F0),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ongoingJobs.isEmpty
          ? const Center(child: Text("No ongoing jobs"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ongoingJobs.length,
        itemBuilder: (context, index) {
          final job = _ongoingJobs[index];
          return Card(
            child: ListTile(
              title: Text(job['jobType'] ?? 'Cleaning Service'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Customer: ${job['customerName'] ?? 'Unknown'}"),
                  Text("${job['date'].split('T')[0]} at ${job['time']} - ${job['totalPrice']} LKR"),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () => _completeJob(job['id']),
                child: const Text("Complete"),
              ),
            ),
          );
        },
      ),
    );
  }
}