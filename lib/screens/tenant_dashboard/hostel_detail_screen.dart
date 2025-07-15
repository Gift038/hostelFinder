import 'package:flutter/material.dart';

class HostelDetailScreen extends StatelessWidget {
  const HostelDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color coffeeBrown = const Color(0xFF4B2E05);
    final Color lightCoffeeBrown = const Color(0xFF9C7A5F);
    final hostel = ModalRoute.of(context)?.settings.arguments as Map?;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5F2),
        foregroundColor: Colors.brown,
        elevation: 0,
        title: Text(hostel?['name'] ?? 'Hostel'),
        leading: BackButton(color: coffeeBrown),
      ),
      body: hostel == null
          ? const Center(child: Text('No hostel data.'))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: Center(
                      child: Text(
                        'Image goes here',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  hostel['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  hostel['description'] ?? '',
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                if (hostel['rooms'] != null) ...[
                  const Text('Room Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...List.generate(hostel['rooms'].length, (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.bed_outlined, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(hostel['rooms'][i]['type'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Text(hostel['rooms'][i]['desc'], style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )),
                  const SizedBox(height: 20),
                ],
                if (hostel['amenities'] != null) ...[
                  const Text('Amenities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...List.generate(hostel['amenities'].length, (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.check_box, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Text(hostel['amenities'][i], style: const TextStyle(fontSize: 15)),
                          ],
                        ),
                      )),
                  const SizedBox(height: 20),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: coffeeBrown,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/matching_hostels');
                    },
                    child: const Text('Book Now', style: TextStyle(fontSize: 16)),
                  ),
                ),
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
