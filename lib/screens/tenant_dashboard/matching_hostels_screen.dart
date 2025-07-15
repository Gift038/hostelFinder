import 'package:flutter/material.dart';

class MatchingHostelsScreen extends StatelessWidget {
  const MatchingHostelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color coffeeBrown = const Color(0xFF4B2E05);
    final Color lightCoffeeBrown = const Color(0xFF9C7A5F);
    final List<Map<String, dynamic>> suggested = [
      {
        'name': 'Mwesigwa Hostel',
        'rating': 9.2,
        'distance': '1.2 miles away',
        'price': '680,000',
        'image': null, // Image should be fetched from backend
        'location': 'Makerere, Uganda',
        'nights': '1 night · 1 guest',
        'description': 'Located near the main campus, this hostel offers a comfortable and secure living environment for students.',
        'rooms': [
          {'type': 'Single Room', 'desc': 'Ideal for individual students'},
          {'type': 'Double Room', 'desc': 'Suitable for sharing with a roommate'},
        ],
        'amenities': [
          'Swimming Pool', 'Gym', 'Laundry', 'Wi-Fi', 'Enhanced Security', 'Playground', 'Parking', 'Shared Kitchen', 'Study Room'
        ]
      },
      {
        'name': 'Braedt Hostel',
        'rating': 8.8,
        'distance': '2.5 miles away',
        'price': '800,000',
        'image': null, // Image should be fetched from backend
      },
      {
        'name': 'Villa Hub Hostel',
        'rating': 9.0,
        'distance': '3.1 miles away',
        'price': '900,000',
        'image': null, // Image should be fetched from backend
      },
    ];
    final List<Map<String, dynamic>> others = [
      {
        'name': 'Backpackers Hostel',
        'rating': 7.5,
        'distance': '4.2 miles away',
        'price': '1,200,000',
        'image': null, // Image should be fetched from backend
      },
      {
        'name': 'Sempa Hostel',
        'rating': 8.0,
        'distance': '5.5 miles away',
        'price': '2,000,000',
        'image': null, // Image should be fetched from backend
      },
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5F2),
        foregroundColor: Colors.brown,
        elevation: 0,
        title: const Text('Matching Hostels'),
        leading: BackButton(color: coffeeBrown),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.grey),
              const SizedBox(width: 4),
              Text('Makerere, Uganda', style: TextStyle(color: Colors.grey[700])),
            ],
          ),
          const SizedBox(height: 4),
          const Text('1 night · 1 guest', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          const Text('Suggested', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          ...suggested.map((hostel) => GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/hostel_detail', arguments: hostel);
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                        child: hostel['image'] != null
                            ? Image.asset(
                                hostel['image']!,
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
                              Text(hostel['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('${hostel['rating']}', style: TextStyle(color: coffeeBrown, fontWeight: FontWeight.bold)),
                              Text(hostel['distance'], style: const TextStyle(color: Colors.grey)),
                              Text(hostel['price'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 16),
          const Text('Other Available Hostels – Not matching your search', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...others.map((hostel) => GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/hostel_detail', arguments: hostel);
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                        child: hostel['image'] != null
                            ? Image.asset(
                                hostel['image']!,
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
                              Text(hostel['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('${hostel['rating']}', style: TextStyle(color: coffeeBrown, fontWeight: FontWeight.bold)),
                              Text(hostel['distance'], style: const TextStyle(color: Colors.grey)),
                              Text(hostel['price'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
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