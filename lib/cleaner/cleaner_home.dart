import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reviews_screen.dart' as CleanerReviews;
import 'notifications_screen.dart' as CleanerNotifs;
import 'home_screen.dart';
import 'find_jobs_screen.dart';
import 'ongoing_jobs.dart';
import 'profile_screen.dart';

class CleanerHome extends StatefulWidget {
  const CleanerHome({super.key});

  @override
  _CleanerHomeState createState() => _CleanerHomeState();
}

class _CleanerHomeState extends State<CleanerHome> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const FindJobsScreen(),
    const OngoingJobsScreen(),
    const ProfileScreen(userType: "Cleaner"),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("CleanZone"),
        backgroundColor: Colors.orange[100],
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            color: Colors.orange,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CleanerReviews.CleanerReviewsScreen()),
              );
            },
          ),
          StreamBuilder<QuerySnapshot>(
            stream: user != null
                ? FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('notifications')
                .where('read', isEqualTo: false)
                .snapshots()
                : null,
            builder: (context, snapshot) {
              bool hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CleanerNotifs.CleanerNotificationsScreen()),
                      );
                    },
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 11,
                      top: 11,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(minWidth: 10, minHeight: 10),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Find Jobs"),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: "Ongoing"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}