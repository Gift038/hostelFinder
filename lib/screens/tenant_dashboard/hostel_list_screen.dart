// hostel_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HostelListScreen extends StatelessWidget {
  const HostelListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Matching Hostels")),
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

          return ListView.builder(
            itemCount: hostels.length,
            itemBuilder: (context, index) {
              final hostel = hostels[index].data() as Map<String, dynamic>;
              final hostelId = hostels[index].id; // Use document ID for navigation

              return ListTile(
                leading: hostel['hostelImages'] != null && hostel['hostelImages'].isNotEmpty
                    ? Image.network(hostel['hostelImages'][0]) // Use first image from hostelImages
                    : const Icon(Icons.image_not_supported), // Fallback if no image
                title: Text(hostel['name'] ?? 'Unnamed Hostel'),
                subtitle: Text(
                  'UGX ${hostel['min_price']?.toString() ?? 'N/A'} - ${hostel['max_price']?.toString() ?? 'N/A'}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Navigator.pushNamed(context, '/hostel_detail', arguments: hostelId),
              );
            },
          );
        },
      ),
    );
  }
}