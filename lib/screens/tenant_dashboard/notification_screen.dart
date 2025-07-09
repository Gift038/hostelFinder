import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color coffeeBrown = Color(0xFF4B2E19);
const Color lightCoffee = Color(0xFFD7CCC8);

class NotificationItem {
  final String title;
  final String body;
  final String type;
  final DateTime timestamp;

  NotificationItem({
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
  });

  factory NotificationItem.fromFirestore(Map<String, dynamic> data) {
    return NotificationItem(
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String? userId;
  final List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'icon': Icons.all_inclusive},
    {'label': 'Booking Status', 'icon': Icons.check_circle_outline},
    {'label': 'Check-in Reminder', 'icon': Icons.calendar_today},
    {'label': 'Hostel Update', 'icon': Icons.notifications},
    {'label': 'New Review', 'icon': Icons.star_border},
  ];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
  }

  List<NotificationItem> _filterNotifications(List<NotificationItem> notifications) {
    switch (_selectedCategory) {
      case 'Booking Status':
        return notifications.where((n) => n.type == 'booking_confirmed' || n.type == 'booking_canceled').toList();
      case 'Check-in Reminder':
        return notifications.where((n) => n.type == 'checkin_reminder').toList();
      case 'Hostel Update':
        return notifications.where((n) => n.type == 'hostel_update').toList();
      case 'New Review':
        return notifications.where((n) => n.type == 'new_review').toList();
      case 'All':
      default:
        return notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: lightCoffee,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: coffeeBrown,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: _categories.map((cat) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  avatar: Icon(cat['icon'], size: 20, color: _selectedCategory == cat['label'] ? Colors.white : coffeeBrown),
                  label: Text(cat['label']),
                  selected: _selectedCategory == cat['label'],
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = cat['label']);
                  },
                  selectedColor: coffeeBrown,
                  backgroundColor: lightCoffee,
                  labelStyle: TextStyle(
                    color: _selectedCategory == cat['label'] ? Colors.white : coffeeBrown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No notifications'));
                }
                final notifications = snapshot.data!.docs
                    .map((doc) => NotificationItem.fromFirestore(doc.data() as Map<String, dynamic>))
                    .toList();
                final filtered = _filterNotifications(notifications);
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final notif = filtered[index];
                    return Card(
                      color: Colors.white,
                      child: ListTile(
                        leading: Icon(Icons.notifications, color: coffeeBrown),
                        title: Text(
                          notif.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: coffeeBrown),
                        ),
                        subtitle: Text(
                          notif.body,
                          style: const TextStyle(color: Colors.brown),
                        ),
                        trailing: Text(
                          '${notif.timestamp.hour}:${notif.timestamp.minute}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: coffeeBrown,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: lightCoffee,
        currentIndex: 1, // Notifications tab
        onTap: (index) {
          // Navigation logic here
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
        ],
      ),
    );
  }

  Future<void> addNotificationToFirestore({
    required String userId,
    required String title,
    required String body,
    required String type,
    DateTime? timestamp,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': title,
      'body': body,
      'type': type,
      'timestamp': timestamp ?? DateTime.now(),
    });
  }
}
