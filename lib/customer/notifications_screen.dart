import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as dev;

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _addReview(BuildContext context, String cleanerId, String jobId) async {
    final ratingController = TextEditingController();
    final commentController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser!;

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Review Cleaner"),
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
                dev.log("Submitting review for cleaner: $cleanerId by customer: ${user.uid}");
                await FirebaseFirestore.instance.collection('reviews').add({
                  'reviewerId': user.uid,
                  'reviewedId': cleanerId,
                  'rating': rating,
                  'comment': commentController.text,
                  'timestamp': FieldValue.serverTimestamp(),
                  'type': 'customer_to_cleaner',
                  'jobId': jobId,
                });
                dev.log("Review submitted successfully");

                try {
                  dev.log("Notifying cleaner: $cleanerId");
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(cleanerId)
                      .collection('notifications')
                      .add({
                    'title': 'New Review Received',
                    'message': 'A customer gave you a $rating-star review: "${commentController.text}"',
                    'timestamp': FieldValue.serverTimestamp(),
                    'read': false,
                    'userId': cleanerId, // Add required userId field
                  });
                  dev.log("Notification sent to cleaner: $cleanerId");
                } catch (notifError) {
                  dev.log("Error notifying cleaner: $notifError", stackTrace: StackTrace.current);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Review submitted, but failed to notify cleaner: $notifError")),
                  );
                  Navigator.pop(dialogContext);
                  return;
                }

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

  Future<bool> _hasReviewedJob(String jobId, String reviewerId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('jobId', isEqualTo: jobId)
        .where('reviewerId', isEqualTo: reviewerId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Notifications")),
        body: const Center(child: Text("Please log in to see notifications")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notifications yet."));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index].data() as Map<String, dynamic>;
              final jobId = notif['jobId'] as String?;
              final isJobCompleted = notif['title'] == 'Job Completed';

              return FutureBuilder<String>(
                future: jobId != null
                    ? FirebaseFirestore.instance.collection('jobs').doc(jobId).get().then((jobDoc) {
                  final cleanerId = jobDoc.data()?['cleanerId'] as String?;
                  if (cleanerId != null) {
                    return _fetchUsername(cleanerId);
                  }
                  return 'Unknown';
                })
                    : Future.value('Unknown'),
                builder: (context, usernameSnapshot) {
                  final cleanerName = usernameSnapshot.data ?? 'Unknown';

                  return FutureBuilder<bool>(
                    future: jobId != null ? _hasReviewedJob(jobId, user.uid) : Future.value(false),
                    builder: (context, reviewSnapshot) {
                      if (reviewSnapshot.connectionState == ConnectionState.waiting) {
                        return const ListTile(title: Text("Loading..."));
                      }

                      final hasReviewed = reviewSnapshot.data ?? false;

                      return ListTile(
                        leading: Icon(
                          notif['title'] == 'Job Completed' ? Icons.check_circle : Icons.cleaning_services,
                          color: notif['title'] == 'Job Completed' ? Colors.green : Colors.orange,
                        ),
                        title: Text(
                          '${notif['title'] ?? 'Notification'} from $cleanerName',
                        ),
                        subtitle: Text(notif['message'] ?? ''),
                        trailing: isJobCompleted && jobId != null
                            ? hasReviewed
                            ? const Text("Reviewed", style: TextStyle(color: Colors.grey))
                            : TextButton(
                          onPressed: () async {
                            final jobDoc = await FirebaseFirestore.instance.collection('jobs').doc(jobId).get();
                            final cleanerId = jobDoc['cleanerId'] as String;
                            await _addReview(context, cleanerId, jobId);
                          },
                          child: const Text("Review Cleaner"),
                        )
                            : Text(
                          notif['timestamp'] != null
                              ? (notif['timestamp'] as Timestamp).toDate().toString().split(' ')[0]
                              : '',
                        ),
                      );
                    },
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