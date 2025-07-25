import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MatchingHostelsScreen extends StatelessWidget {
  const MatchingHostelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color coffeeBrown = const Color(0xFF4B2E05);
    final Color lightCoffeeBrown = const Color(0xFF9C7A5F);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5F2),
        foregroundColor: Colors.brown,
        elevation: 0,
        title: const Text('Matching Hostels'),
        leading: BackButton(color: coffeeBrown),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('hostels').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading hostels'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final hostels = snapshot.data!.docs;
          if (hostels.isEmpty) {
            return const Center(child: Text('No hostels found.'));
          }
          return ListView.builder(
        padding: const EdgeInsets.all(24),
            itemCount: hostels.length,
            itemBuilder: (context, index) {
              final hostel = hostels[index].data() as Map<String, dynamic>;
              final images = (hostel['hostelImages'] ?? hostel['imageUrls'] ?? []) as List?;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                      child: images != null && images.isNotEmpty
                          ? Image.network(
                              images[0],
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                            )
                          : Container(
                              width: 90,
                              height: 90,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                              ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            Text(hostel['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                            Text('${hostel['rating'] ?? ''}', style: TextStyle(color: coffeeBrown, fontWeight: FontWeight.bold)),
                            Text(hostel['location'] ?? '', style: const TextStyle(color: Colors.grey)),
                            Text('UGX ${hostel['price'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.brown[100],
        type: BottomNavigationBarType.fixed,
        selectedItemColor: coffeeBrown,
        unselectedItemColor: lightCoffeeBrown,
        currentIndex: 0,
        onTap: (index) {},
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.house_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cases_rounded),
            label: "Documents",
          ),
        ],
      ),
    );
  }
} 