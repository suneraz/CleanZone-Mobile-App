import 'package:flutter/material.dart';
import 'post_job_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            title: const Text("Book a Cleaning Service"),
            subtitle: const Text("Quick and easy home cleaning"),
            trailing: const Icon(Icons.cleaning_services),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PostJobScreen()),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Popular Services",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ModifiedServiceCard(
          title: "Regular Cleaning",
          description: "Standard home cleaning",
          price: "Starts at 1800 LKR",
          currency: "",
          imageUrl: "assets/regular.jpg",
          onViewDetails: () {
            _showDetailsDialog(
              context,
              "Regular Cleaning Pricing",
              "Base Package: 1800 LKR\n\n• First room included in base price\n• Additional rooms: 500 LKR per room\n• First bathroom: 500 LKR\n• Additional bathrooms: 800 LKR each\n\nService includes standard dusting, vacuuming, mopping, and surface cleaning.",
            );
          },
        ),
        ModifiedServiceCard(
          title: "Deep Cleaning",
          description: "Detailed cleaning",
          price: "Starts at 2500 LKR",
          currency: "",
          imageUrl: "assets/deep.jpg",
          onViewDetails: () {
            _showDetailsDialog(
              context,
              "Deep Cleaning Pricing",
              "Base Package: 2500 LKR\n\n• First room included in base price\n• Additional rooms: 500 LKR per room\n• First bathroom: 500 LKR\n• Additional bathrooms: 800 LKR each\n\nIncludes thorough cleaning of all surfaces, fixtures, corners, and hard-to-reach areas.",
            );
          },
        ),
        ModifiedServiceCard(
          title: "Window Cleaning",
          description: "Crystal clear windows",
          price: "Starts at 1500 LKR",
          currency: "",
          imageUrl: "assets/window.jpg",
          onViewDetails: () {
            _showDetailsDialog(
              context,
              "Window Cleaning Pricing",
              "Base Package: 1500 LKR\n\n• First room's windows included in base price\n• Additional rooms: 500 LKR per room\n• Bathroom windows: First bathroom 500 LKR\n• Additional bathroom windows: 800 LKR each\n\nIncludes interior and exterior window cleaning with professional streak-free results.",
            );
          },
        ),
      ],
    );
  }

  void _showDetailsDialog(BuildContext context, String title, String simplifiedDescription) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(simplifiedDescription),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}

class ModifiedServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final String price;
  final String currency;
  final String imageUrl;
  final VoidCallback onViewDetails;

  const ModifiedServiceCard({
    super.key,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.imageUrl,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 160,
            height: 160,
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Text(
                        "img",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(description),
                  const SizedBox(height: 9),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "$currency $price",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800]),
                    ),
                  ),
                  const SizedBox(height: 9),
                  TextButton(
                    onPressed: onViewDetails,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      alignment: Alignment.centerLeft,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: const BorderSide(color: Colors.black),
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                    child: const Text(
                      "View Details",
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}