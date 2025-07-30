import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _markAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }

  Future<void> _markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Modified: Get all notifications for user first, then filter unread ones
    final notifications = await _firestore
        .collection('notifications')
        .where('managerId', isEqualTo: user.uid)
        .get();

    final batch = _firestore.batch();
    
    // Filter unread notifications in code rather than query
    for (var doc in notifications.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final read = data['read'] as bool? ?? false;
      
      if (!read) {
        batch.update(doc.reference, {'read': true});
      }
    }

    await batch.commit();
  }

  Color _getNotificationColor(String type) {
    switch (type.toUpperCase()) {
      case 'PAYMENT':
        return Colors.green[100]!;
      case 'MAINTENANCE':
        return Colors.orange[100]!;
      case 'BOOKING':
        return Colors.blue[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toUpperCase()) {
      case 'PAYMENT':
        return Icons.payment;
      case 'MAINTENANCE':
        return Icons.build;
      case 'BOOKING':
        return Icons.book_online;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view notifications'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Modified: Only filter by managerId, sort in code
        stream: _firestore
            .collection('notifications')
            .where('managerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications'));
          }

          // Sort notifications by createdAt in code
          final docs = snapshot.data!.docs;
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aCreatedAt = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final bCreatedAt = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            return bCreatedAt.compareTo(aCreatedAt); // Descending order
          });

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final type = data['type'] as String? ?? 'OTHER';
              final read = data['read'] as bool? ?? false;
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

              return Dismissible(
                key: Key(doc.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _firestore.collection('notifications').doc(doc.id).delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification deleted')),
                  );
                },
                child: Card(
                  color: read ? null : _getNotificationColor(type),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Icon(
                        _getNotificationIcon(type),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(data['message'] ?? 'No message'),
                    subtitle: Text(
                      DateFormat('MMM dd, yyyy hh:mm a').format(createdAt),
                    ),
                    trailing: !read
                        ? IconButton(
                            icon: const Icon(Icons.mark_email_read),
                            onPressed: () => _markAsRead(doc.id),
                          )
                        : null,
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