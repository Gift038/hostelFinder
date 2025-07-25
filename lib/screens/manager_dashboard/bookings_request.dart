import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingsRequestScreen extends StatefulWidget {
  const BookingsRequestScreen({super.key});

  @override
  BookingsRequestScreenState createState() => BookingsRequestScreenState();
}

class BookingsRequestScreenState extends State<BookingsRequestScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> _fetchBookingRequests() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    // This query assumes you have a `managerId` field on each booking request.
    // You may need to adjust this based on your database structure.
    return _firestore
        .collection('booking_requests')
        .where('managerId', isEqualTo: user.uid)
        .snapshots();
  }

  Future<void> _updateBookingStatus(String bookingId, String status, {String? hostelId, String? roomId, String? tenantId}) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final bookingRef = _firestore.collection('booking_requests').doc(bookingId);
        transaction.update(bookingRef, {'status': status});

        if (status == 'Approved' && hostelId != null && roomId != null && tenantId != null) {
          final roomRef = _firestore.collection('hostels').doc(hostelId).collection('rooms').doc(roomId);
          transaction.update(roomRef, {
            'isOccupied': true,
            'tenantId': tenantId,
          });
          
          final userRef = _firestore.collection('users').doc(tenantId);
          transaction.update(userRef, {
            'assignedHostel': hostelId,
            'assignedRoom': roomId,
          });
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking has been $status.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update booking: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Requests'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchBookingRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No new booking requests.'));
          }
          final requests = snapshot.data!.docs;
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final data = request.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'Pending';
              
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('Request from: ${data['tenantName'] ?? 'N/A'}'),
                  subtitle: Text('Hostel: ${data['hostelName'] ?? 'N/A'}\nRoom: ${data['roomNumber'] ?? 'N/A'}'),
                  isThreeLine: true,
                  trailing: status == 'Pending'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () => _updateBookingStatus(
                                request.id,
                                'Approved',
                                hostelId: data['hostelId'],
                                roomId: data['roomId'],
                                tenantId: data['tenantId'],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _updateBookingStatus(request.id, 'Rejected'),
                            ),
                          ],
                        )
                      : Text(status, style: TextStyle(color: status == 'Approved' ? Colors.green : Colors.red)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
