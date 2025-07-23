import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../chat/chat_screen.dart';

class HostelDetailScreen extends StatelessWidget {
  const HostelDetailScreen({super.key});

  Future<String> _createOrGetChatRoom(String otherUserId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    final currentUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final otherUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(otherUserId);
    final ids = [user.uid, otherUserId];
    ids.sort();
    final chatRoomId = ids.join('_');
    final chatRoomRef = FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId);
    final doc = await chatRoomRef.get();
    if (!doc.exists) {
      await chatRoomRef.set({
        'users': [user.uid, otherUserId],
        'userRefs': [currentUserRef, otherUserRef],
      });
    }
    return chatRoomId;
  }

  @override
  Widget build(BuildContext context) {
    final hostel = ModalRoute.of(context)?.settings.arguments as Map?;
    return Scaffold(
      appBar: AppBar(
        title: Text(hostel?['name'] ?? 'Hostel'),
        centerTitle: true,
      ),
      body: hostel == null
          ? const Center(child: Text('No hostel data.'))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Hostel Image (with Hero animation for modern effect)
                Hero(
                  tag: 'hostel_image_${hostel['name'] ?? ''}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child:
                          hostel['imageUrls'] != null &&
                              hostel['imageUrls'].isNotEmpty
                          ? Image.network(
                              hostel['imageUrls'][0],
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Text(
                                'No image',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  hostel['name'] ?? '',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  hostel['description'] ?? '',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                if (hostel['rooms'] != null) ...[
                  Text(
                    'Room Options',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(
                    hostel['rooms'].length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.bed_outlined, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            hostel['rooms'][i]['type'],
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hostel['rooms'][i]['desc'],
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (hostel['amenities'] != null) ...[
                  Text(
                    'Amenities',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: List.generate(
                      hostel['amenities'].length,
                      (i) => Chip(
                        label: Text(hostel['amenities'][i]),
                        avatar: const Icon(
                          Icons.check_box,
                          color: Colors.amber,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                FilledButton.icon(
                  icon: const Icon(Icons.bed),
                  label: const Text('Book Now'),
                  onPressed: () {
                    if (hostel['rooms'] != null &&
                        hostel['rooms'].isNotEmpty) {
                      Navigator.pushNamed(
                        context,
                        '/booking',
                        arguments: {
                          'hostelName': hostel['name'],
                          'roomType': hostel['rooms'][0]['type'],
                          'roomPrice': hostel['rooms'][0]['price'],
                        },
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No rooms available for booking.'),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.message),
                  label: const Text('Contact Manager'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: () async {
                    try {
                      final managerId =
                          hostel['managerId'] as String? ??
                          'manager_placeholder_id';
                      final otherUserName =
                          hostel['managerName'] as String? ?? 'Manager';
                      if (managerId == 'manager_placeholder_id') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Manager information not available yet.',
                            ),
                          ),
                        );
                        return;
                      }
                      final chatRoomId = await _createOrGetChatRoom(managerId);
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatRoomId: chatRoomId,
                            otherUserName: otherUserName,
                          ),
                        ),
                      );
                    } catch (e) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to start chat: \\${e.toString()}',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.house_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(icon: Icon(Icons.payment), label: 'Payments'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          NavigationDestination(
            icon: Icon(Icons.cases_rounded),
            label: 'Documents',
          ),
        ],
        onDestinationSelected: (_) {},
      ),
    );
  }
}
