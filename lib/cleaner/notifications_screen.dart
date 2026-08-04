import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as dev;

class CleanerNotificationsScreen extends StatelessWidget {
  const CleanerNotificationsScreen({super.key});

  Future<void> _markAsRead(String notifId, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notifId)
          .update({'read': true});
      dev.log("Marked notification $notifId as read");
    } catch (e) {
      dev.log("Error marking notification as read: $e");
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
              final notifId = notifications[index].id;
              final isRead = notif['read'] as bool? ?? false;
              final jobId = notif['jobId'] as String?;

              // Mark as read when viewed
              if (!isRead) {
                _markAsRead(notifId, user.uid);
              }

              return FutureBuilder<String>(
                future: jobId != null
                    ? FirebaseFirestore.instance.collection('jobs').doc(jobId).get().then((jobDoc) {
                  final customerId = jobDoc.data()?['customerId'] as String?;
                  if (customerId != null) {
                    return _fetchUsername(customerId);
                  }
                  return 'Customer';
                })
                    : Future.value('Unknown'),
                builder: (context, usernameSnapshot) {
                  final customerName = usernameSnapshot.data ?? 'Unknown';

                  return ListTile(
                    leading: Icon(
                      notif['title'] == 'New Review Received'
                          ? Icons.star
                          : Icons.notifications,
                      color: notif['title'] == 'New Review Received'
                          ? Colors.amber
                          : Colors.grey,
                    ),
                    title: Text(
                      '${notif['title'] ?? 'Notification'} from $customerName',
                    ),
                    subtitle: Text(notif['message'] ?? ''),
                    trailing: Text(
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
      ),
    );
  }
}