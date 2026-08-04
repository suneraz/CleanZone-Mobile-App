import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as dev;

class CleanerReviewsScreen extends StatelessWidget {
  const CleanerReviewsScreen({super.key});

  Future<String> _fetchUsername(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.data()?['username'] ?? 'Unknown';
    } catch (e) {
      dev.log("Error fetching username for UID $uid: $e");
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Reviews")),
        body: const Center(child: Text("Please log in to see reviews")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Reviews")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('reviewedId', isEqualTo: user.uid)
            .where('type', isEqualTo: 'customer_to_cleaner')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          dev.log("CleanerReviewsScreen: ConnectionState=${snapshot.connectionState}, HasData=${snapshot.hasData}, HasError=${snapshot.hasError}");

          if (snapshot.connectionState == ConnectionState.waiting) {
            dev.log("Waiting for reviews stream...");
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            dev.log("Error in reviews stream: ${snapshot.error}");
            return Center(child: Text("Error loading reviews: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            dev.log("No reviews found for cleaner: ${user.uid}");
            return const Center(child: Text("No reviews yet."));
          }

          final reviews = snapshot.data!.docs;
          dev.log("Fetched ${reviews.length} reviews for cleaner: ${user.uid}");

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index].data() as Map<String, dynamic>;
              final reviewerId = review['reviewerId'] as String;

              return FutureBuilder<String>(
                future: _fetchUsername(reviewerId),
                builder: (context, usernameSnapshot) {
                  final reviewerName = usernameSnapshot.data ?? 'Unknown';
                  dev.log("Review ${index + 1}: $review, Reviewer: $reviewerName");
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(reviewerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(
                              5,
                                  (i) => Icon(i < (review['rating'] as int) ? Icons.star : Icons.star_border, color: Colors.amber),
                            ),
                          ),
                          Text(review['comment'] as String),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}