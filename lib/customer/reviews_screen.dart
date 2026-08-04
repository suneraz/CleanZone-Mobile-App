import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as dev;
import 'dart:async';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  _ReviewsScreenState createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final _auth = FirebaseAuth.instance;
  late final Stream<QuerySnapshot> _reviewsStream;
  List<Map<String, dynamic>>? lastReviews;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      dev.log("Setting up reviews stream for user: ${user.uid}");
      _reviewsStream = FirebaseFirestore.instance
          .collection('reviews')
          .where('reviewedId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'cleaner_to_customer')
          .orderBy('timestamp', descending: true)
          .snapshots();

      // Log reviews count periodically
      Timer.periodic(const Duration(seconds: 1), (timer) {
        dev.log("Current reviews count: ${lastReviews?.length ?? 0}");
        if (lastReviews != null && lastReviews!.isNotEmpty) {
          dev.log("Current reviews: ${lastReviews!.map((r) => r['comment']).join(', ')}");
        } else {
          dev.log("No reviews cached");
        }
      });
    }
  }

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
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Reviews")),
        body: const Center(child: Text("Please log in to see reviews")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Reviews")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _reviewsStream,
        builder: (context, snapshot) {
          dev.log("StreamBuilder state: ConnectionState=${snapshot.connectionState}, HasData=${snapshot.hasData}, HasError=${snapshot.hasError}");

          if (snapshot.connectionState == ConnectionState.waiting && lastReviews == null) {
            dev.log("Waiting for reviews stream to load...");
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            dev.log("Error in reviews stream: ${snapshot.error} - Stack trace: ${snapshot.stackTrace}");
            return Center(child: Text("Error loading reviews: ${snapshot.error}"));
          }
          if (snapshot.hasData) {
            final currentReviews = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              dev.log("Review document ID: ${doc.id}, Data: $data");
              return data;
            }).toList();
            if (currentReviews.isNotEmpty) {
              lastReviews = currentReviews;
              dev.log("Received ${lastReviews!.length} reviews for user: ${user.uid} - Reviews: ${lastReviews!.map((r) => r['comment']).join(', ')}");
            } else {
              dev.log("No data in current snapshot for user: ${user.uid}");
              if (lastReviews == null || lastReviews!.isEmpty) {
                return const Center(child: Text("No reviews yet."));
              }
            }
          } else {
            dev.log("Snapshot has no data for user: ${user.uid}");
            if (lastReviews == null || lastReviews!.isEmpty) {
              return const Center(child: Text("No reviews yet."));
            }
          }

          final reviews = lastReviews ?? [];
          dev.log("Displaying ${reviews.length} reviews for user: ${user.uid}");

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              final reviewerId = review['reviewerId'] as String;

              return FutureBuilder<String>(
                future: _fetchUsername(reviewerId),
                builder: (context, usernameSnapshot) {
                  final reviewerName = usernameSnapshot.data ?? 'Unknown';
                  dev.log("Displaying review: ${review.toString()}, Reviewer: $reviewerName");
                  return ReviewCard(
                    name: reviewerName,
                    rating: review['rating'] as int? ?? 0,
                    review: review['comment'] as String? ?? 'No comment',
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

class ReviewCard extends StatelessWidget {
  final String name;
  final int rating;
  final String review;

  const ReviewCard({super.key, required this.name, required this.rating, required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                5,
                    (index) => Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
              ),
            ),
            Text(review),
          ],
        ),
      ),
    );
  }
}