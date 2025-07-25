import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HostelDetailScreen extends StatelessWidget {
  const HostelDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color coffeeBrown = const Color(0xFF4B2E05);
    final Color lightCoffeeBrown = const Color(0xFF9C7A5F);
    final String? hostelId = ModalRoute.of(context)?.settings.arguments as String?;
    if (hostelId == null) {
      return const Scaffold(
        body: Center(child: Text('No hostel selected.')),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5F2),
        foregroundColor: Colors.brown,
        elevation: 0,
        title: const Text('Hostel'),
        leading: BackButton(color: coffeeBrown),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('hostels').doc(hostelId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Hostel not found.'));
          }
          final hostel = snapshot.data!.data() as Map<String, dynamic>;
          final images = (hostel['hostelImages'] ?? hostel['imageUrls'] ?? []) as List?;
          return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                child: images != null && images.isNotEmpty
                    ? Image.network(
                        images[0],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                      )
                    : Container(
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
              if (hostel['rooms'] != null)
                ...[const Text('Room Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...List.generate((hostel['rooms'] as List).length, (i) => Padding(
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
            ],
          );
                    },
      ),
    );
  }
}
