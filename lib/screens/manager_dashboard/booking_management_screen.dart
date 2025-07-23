import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';

class BookingManagementScreen extends StatefulWidget {
  const BookingManagementScreen({super.key});

  @override
  State<BookingManagementScreen> createState() =>
      _BookingManagementScreenState();
}

class _BookingManagementScreenState extends State<BookingManagementScreen> {
  String _selectedStatus = 'PENDING';
  String? _selectedHostelId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Management')),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildBookingsList()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('hostels')
                .where(
                  'managerId',
                  isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                )
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();

              final hostels = snapshot.data!.docs;
              if (_selectedHostelId == null && hostels.isNotEmpty) {
                _selectedHostelId = hostels.first.id;
              }

              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Hostel'),
                value: _selectedHostelId,
                items: hostels.map((hostel) {
                  final data = hostel.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: hostel.id,
                    child: Text(data['name'] ?? 'Unnamed Hostel'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedHostelId = value),
              );
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Booking Status'),
            value: _selectedStatus,
            items: ['PENDING', 'APPROVED', 'REJECTED'].map((status) {
              return DropdownMenuItem(value: status, child: Text(status));
            }).toList(),
            onChanged: (value) => setState(() => _selectedStatus = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList() {
    if (_selectedHostelId == null) {
      return const Center(
        child: Text('Please select a hostel to view bookings.'),
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('hostelId', isEqualTo: _selectedHostelId)
          .where('status', isEqualTo: _selectedStatus)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final bookings = snapshot.data?.docs ?? [];
        if (bookings.isEmpty) {
          return Center(
            child: Text('No ${_selectedStatus.toLowerCase()} bookings found.'),
          );
        }
        return ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return _BookingListItem(
              bookingId: booking.id,
              bookingData: booking.data() as Map<String, dynamic>,
            );
          },
        );
      },
    );
  }
}

class _BookingListItem extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const _BookingListItem({required this.bookingId, required this.bookingData});

  @override
  State<_BookingListItem> createState() => _BookingListItemState();
}

class _BookingListItemState extends State<_BookingListItem> {
  final _notificationService = NotificationService();
  bool _isLoading = false;

  Future<void> _updateBookingStatus(String status) async {
    setState(() => _isLoading = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final bookingRef = FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId);
      batch.update(bookingRef, {'status': status});

      if (status == 'APPROVED') {
        final hostelRef = FirebaseFirestore.instance
            .collection('hostels')
            .doc(widget.bookingData['hostelId']);
        final roomRef = hostelRef
            .collection('rooms')
            .doc(widget.bookingData['roomId']);
        batch.update(hostelRef, {'occupiedRooms': FieldValue.increment(1)});
        batch.update(roomRef, {
          'isOccupied': true,
          'tenantId': widget.bookingData['tenantId'],
          'occupiedSince': FieldValue.serverTimestamp(),
        });
        final paymentRef = FirebaseFirestore.instance
            .collection('payments')
            .doc();
        batch.set(paymentRef, {
          'bookingId': widget.bookingId,
          'managerId': FirebaseAuth.instance.currentUser?.uid,
          'tenantId': widget.bookingData['tenantId'],
          'tenantName': widget.bookingData['tenantName'],
          'hostelId': widget.bookingData['hostelId'],
          'roomId': widget.bookingData['roomId'],
          'roomNumber': widget.bookingData['roomNumber'],
          'amount': widget.bookingData['amount'],
          'date': widget.bookingData['checkInDate'],
          'status': 'PENDING',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      await _notificationService.createNotification(
        managerId: widget.bookingData['tenantId'],
        type: 'BOOKING_UPDATE',
        message:
            'Your booking request for Room ${widget.bookingData['roomNumber']} has been $status.',
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Booking $status')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = (widget.bookingData['createdAt'] as Timestamp).toDate();
    final checkInDate = (widget.bookingData['checkInDate'] as Timestamp)
        .toDate();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text('Room ${widget.bookingData['roomNumber']}'),
        subtitle: Text('Requested on ${DateFormat.yMMMd().format(createdAt)}'),
        children: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: LinearProgressIndicator(),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Tenant', widget.bookingData['tenantName']),
                      _buildInfoRow(
                        'Amount',
                        'UGX ${NumberFormat('#,###').format(widget.bookingData['amount'])}',
                      ),
                      _buildInfoRow(
                        'Check-in',
                        DateFormat.yMMMd().format(checkInDate),
                      ),
                      if (widget.bookingData['status'] == 'PENDING') ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            FilledButton.icon(
                              onPressed: () => _updateBookingStatus('APPROVED'),
                              icon: const Icon(Icons.check),
                              label: const Text('Approve'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () => _updateBookingStatus('REJECTED'),
                              icon: const Icon(Icons.close),
                              label: const Text('Reject'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
