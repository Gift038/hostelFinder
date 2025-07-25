import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;

class BroadcastMessagesScreen extends StatefulWidget {
  const BroadcastMessagesScreen({super.key});

  @override
  _BroadcastMessagesScreenState createState() =>
      _BroadcastMessagesScreenState();
}

class _BroadcastMessagesScreenState extends State<BroadcastMessagesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<QuerySnapshot>? _broadcastsStream;

  @override
  void initState() {
    super.initState();
    _fetchBroadcastsForTenant();
  }

  Future<void> _fetchBroadcastsForTenant() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // First, find out which hostel the tenant is assigned to.
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final assignedHostelId =
        (userDoc.data() as Map<String, dynamic>)['assignedHostel'] as String?;

    if (assignedHostelId != null) {
      setState(() {
        _broadcastsStream = _firestore
            .collection('broadcasts')
            .where('hostelId', isEqualTo: assignedHostelId)
            .orderBy('timestamp', descending: true)
            .snapshots();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _broadcastsStream,
        builder: (context, snapshot) {
          if (_broadcastsStream == null) {
            return const Center(
              child: Text('You are not currently assigned to a hostel.'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No announcements for your hostel.'),
            );
          }
          final messages = snapshot.data!.docs;
          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final data = message.data() as Map<String, dynamic>;
              final timestamp =
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.campaign),
                  title: Text(data['message'] ?? 'No message content.'),
                  subtitle: Text('Sent ${timeago.format(timestamp)}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
