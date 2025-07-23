import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PublishedAdsScreen extends StatefulWidget {
  const PublishedAdsScreen({super.key});

  @override
  PublishedAdsScreenState createState() => PublishedAdsScreenState();
}

class PublishedAdsScreenState extends State<PublishedAdsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _sendBookingRequest(
    String adId,
    String managerId,
    String hostelId,
    String roomId,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final tenantName =
        (userDoc.data() as Map<String, dynamic>)['fullName'] ?? 'N/A';

    final hostelDoc = await _firestore
        .collection('hostels')
        .doc(hostelId)
        .get();
    final hostelName =
        (hostelDoc.data() as Map<String, dynamic>)['name'] ?? 'N/A';

    final roomDoc = await _firestore
        .collection('hostels')
        .doc(hostelId)
        .collection('rooms')
        .doc(roomId)
        .get();
    final roomNumber =
        (roomDoc.data() as Map<String, dynamic>)['roomNumber'] ?? 'N/A';

    try {
      await _firestore.collection('booking_requests').add({
        'adId': adId,
        'managerId': managerId,
        'tenantId': user.uid,
        'tenantName': tenantName,
        'hostelId': hostelId,
        'hostelName': hostelName,
        'roomId': roomId,
        'roomNumber': roomNumber,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking request sent!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Vacant Rooms')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('published_ads')
            .orderBy('publishedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No vacant rooms are currently advertised.'),
            );
          }
          final ads = snapshot.data!.docs;
          return ListView.builder(
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final ad = ads[index];
              final data = ad.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'],
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(data['description']),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _sendBookingRequest(
                          ad.id,
                          data['managerId'],
                          data['hostelId'],
                          data['roomId'],
                        ),
                        child: const Text('Send Booking Request'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
